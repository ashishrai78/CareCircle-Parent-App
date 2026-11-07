import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../data/repositories/features/sound_listener_repository.dart';
import '../../../data/services/webrtc_audio_receiver.dart';
import '../../../data/services/webrtc_config.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/snackbars.dart';
import '../services/parent_audio_notification_service.dart';

/// 🎧 SoundListenerController — Parent-side controller for listening to child's mic
///
/// Refactored for background playback & persistent session:
///  ✅ Stays active across screens (User can navigate dashboard while audio plays)
///  ✅ Back press navigates instantly without delay or stopping audio
///  ✅ Stop Audio button in Dashboard AppBar & SoundListenerScreen
///  ✅ Ongoing Notification with STOP action (like a music app)
///  ✅ App lifecycle listener (resets sync_mic if app is killed/RAM cleared)
class SoundListenerController extends GetxController
    with WidgetsBindingObserver {
  SoundListenerController({String? initialChildUid, String? initialChildName}) {
    if (initialChildUid != null && initialChildUid.isNotEmpty) {
      childUid.value = initialChildUid;
    }
    if (initialChildName != null && initialChildName.isNotEmpty) {
      childName.value = initialChildName;
    }
  }

  /// Singleton access across all screens
  static SoundListenerController get instance {
    if (!Get.isRegistered<SoundListenerController>()) {
      return Get.put(SoundListenerController(), permanent: true);
    }
    return Get.find<SoundListenerController>();
  }

  /// Child's user UID
  final RxString childUid = ''.obs;

  /// Child's display name
  final RxString childName = ''.obs;

  final SoundListenerRepository _repository = SoundListenerRepository();
  final WebRTCAudioReceiver _receiver = WebRTCAudioReceiver();

  // ============ Reactive State for UI ============

  /// Current connection state
  final Rx<WebRTCConnectionState> connectionState =
      WebRTCConnectionState.idle.obs;

  /// Whether we're in pre-flight checks phase
  final RxBool isPreparing = false.obs;

  /// Whether actively listening (connected)
  final RxBool isListening = false.obs;

  /// Whether in transient state (connecting / waiting)
  final RxBool isConnecting = false.obs;

  /// Whether an error occurred
  final RxBool hasError = false.obs;

  /// Error message for UI
  final RxString errorMessage = ''.obs;

  /// Status label for UI
  final RxString statusLabel = 'Tap Start Listening'.obs;

  /// Child mic state from child_control (streaming, connecting, healing_1..3, blocked_*)
  final RxString micState = ''.obs;

  /// Elapsed time (in seconds) since connection established
  final RxInt elapsedSeconds = 0.obs;

  /// Child online status (from pre-flight check)
  final RxBool isChildOnline = false.obs;

  /// Current session call ID
  String? _currentCallId;

  /// Whether a session is currently active
  bool get isSessionActive => _currentCallId != null;

  Timer? _elapsedTimer;
  StreamSubscription<Map<String, dynamic>?>? _controlSub;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Wire up receiver callbacks
    _receiver.onStateChanged = _onConnectionStateChanged;
    _receiver.onError = _onError;

    // Listen for notification STOP button click from Android system tray
    ParentAudioNotificationService.initialize(
      onStopPressed: () async {
        debugPrint(
          'SoundListener: Stop received from native notification tray',
        );
        if (isSessionActive || isListening.value) {
          await stopListening();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When parent app is swiped from recents / killed / detached from engine
    if (state == AppLifecycleState.detached) {
      debugPrint(
        'SoundListener: 🚨 App detached / RAM cleared — emergency stop sync_mic',
      );
      if (childUid.value.isNotEmpty) {
        _repository.stopMicListening(childUid.value).catchError((_) {});
        ParentAudioNotificationService.hideListeningNotification();
      }
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    ParentAudioNotificationService.hideListeningNotification();
    _elapsedTimer?.cancel();
    _controlSub?.cancel();
    _receiver.stop();
    super.onClose();
  }

  // ============ PUBLIC API ============

  /// Start listening to child's surroundings
  Future<void> startListening({
    String? targetChildUid,
    String? targetChildName,
  }) async {
    if (targetChildUid != null && targetChildUid.isNotEmpty) {
      if (childUid.value.isNotEmpty &&
          childUid.value != targetChildUid &&
          isSessionActive) {
        // If switching children, stop previous session first
        await stopListening();
      }
      childUid.value = targetChildUid;
    }

    if (targetChildName != null && targetChildName.isNotEmpty) {
      childName.value = targetChildName;
    }

    if (childUid.value.isEmpty) {
      _onError('No child device selected.');
      return;
    }

    if (isSessionActive) {
      debugPrint(
        'SoundListener: Session already active for ${childUid.value} — skipping re-start',
      );
      return;
    }

    // Reset state
    hasError.value = false;
    errorMessage.value = '';
    isListening.value = false;
    isConnecting.value = true;
    isPreparing.value = true;
    statusLabel.value = 'Checking prerequisites...';
    connectionState.value = WebRTCConnectionState.initializing;

    try {
      // ============ PRE-FLIGHT CHECK 1: Internet ============
      final isOnline = await NetworkManager.instance.isConnected();
      if (!isOnline) {
        _onError(
          'No internet connection. Please check your network and try again.',
        );
        return;
      }

      // ============ PRE-FLIGHT CHECK 2: Child online ============
      statusLabel.value = 'Checking child device...';
      final childOnline = await _repository.isChildOnline(childUid.value);
      isChildOnline.value = childOnline;

      if (!childOnline) {
        _onError(
          'Child device appears to be offline. '
          'Make sure the child\'s phone is on and connected to the internet.',
        );
        return;
      }

      // ============ STEP 1: Generate callId ============
      _currentCallId = WebRTCConfig.generateCallId(childUid.value);
      debugPrint('SoundListener: Generated callId = $_currentCallId');

      // ============ STEP 2: Send sync_mic=true to child ============
      isPreparing.value = false;
      statusLabel.value = 'Notifying child device...';
      await _repository.startMicListening(
        childUid: childUid.value,
        callId: _currentCallId!,
      );
      debugPrint('SoundListener: ✅ Wrote sync_mic=true + call_id');

      // Listen to child_control for state changes
      _controlSub = _repository.streamChildControl(childUid.value).listen((
        data,
      ) async {
        if (data == null) return;

        final docCallId = data['call_id'] as String?;
        // Ignore stale document snapshots from previous sessions
        if (docCallId != null &&
            docCallId != _currentCallId &&
            !docCallId.startsWith('$_currentCallId-h')) {
          return;
        }

        // A) Real mic status UI
        final childMicState = data['mic_state'] as String?;
        if (childMicState != null && childMicState.isNotEmpty) {
          _updateMicStateUI(childMicState);
        }

        // If child clears sync_mic (e.g., user revoked mic permission or stopped)
        if (data['sync_mic'] == false && isListening.value) {
          _onError('Child device stopped the mic stream.');
          return;
        }

        // B) Auto-heal: Check if child changed call_id (e.g., xxx -> xxx-h1)
        final syncMic = data['sync_mic'] == true;
        final newCallId = data['call_id'] as String?;
        if (syncMic &&
            newCallId != null &&
            newCallId.isNotEmpty &&
            newCallId != _currentCallId) {
          debugPrint(
            'SoundListener: 🔄 Child auto-healed call_id: $_currentCallId -> $newCallId',
          );
          _currentCallId = newCallId;
          statusLabel.value = 'Re-establishing audio session...';
          isConnecting.value = true;
          try {
            await _receiver.start(newCallId);
          } catch (e) {
            debugPrint(
              'SoundListener: ❌ Failed to restart receiver on heal: $e',
            );
            _onError('Failed to reconnect after mic recovery: $e');
          }
        }
      });

      // ============ STEP 3: Start WebRTC receiver ============
      statusLabel.value = 'Connecting to child device...';
      await _receiver.start(_currentCallId!);
    } catch (e, stackTrace) {
      debugPrint('SoundListener: ❌ Start failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _onError('Failed to start listening: $e');
    }
  }

  bool _isStopping = false;

  /// Stop listening to child's surroundings
  Future<void> stopListening() async {
    if (_isStopping) return;
    _isStopping = true;
    try {
      debugPrint('SoundListener: Stopping session');

      // Dismiss notification from phone tray
      ParentAudioNotificationService.hideListeningNotification();

      // Stop elapsed timer
      _elapsedTimer?.cancel();
      _elapsedTimer = null;

      // Stop listening to child_control
      await _controlSub?.cancel();
      _controlSub = null;

      final targetCallId = _currentCallId;
      final targetChildUid = childUid.value;

      // Reset state immediately so UI updates instantly
      _currentCallId = null;
      micState.value = '';
      isListening.value = false;
      isConnecting.value = false;
      isPreparing.value = false;
      elapsedSeconds.value = 0;
      statusLabel.value = 'Stopped';
      connectionState.value = WebRTCConnectionState.closed;

      // Stop WebRTC receiver
      try {
        await _receiver.stop();
      } catch (e) {
        debugPrint('SoundListener: Receiver stop error: $e');
      }

      // Clean up call signaling document in background
      if (targetCallId != null) {
        _repository.cleanupCallDocument(targetCallId).catchError((e) {
          debugPrint('SoundListener: Cleanup call doc error: $e');
        });
      }

      // Clear sync_mic flag + delete call_id from child_control
      if (targetChildUid.isNotEmpty) {
        try {
          await _repository.stopMicListening(targetChildUid);
          debugPrint(
            'SoundListener: ✅ Cleared sync_mic + call_id for $targetChildUid',
          );
        } catch (e) {
          debugPrint('SoundListener: ⚠️ Firestore clear error: $e');
        }
      }
    } finally {
      _isStopping = false;
    }
  }

  /// Retry connection (after failure)
  Future<void> retry() async {
    await stopListening();
    await Future.delayed(const Duration(milliseconds: 500));
    await startListening();
  }

  /// Stop sound button handler (stops audio but doesn't force pop)
  Future<void> onStopPressed() async {
    await stopListening();
  }

  // ============ PRIVATE CALLBACKS ============

  void _onConnectionStateChanged(WebRTCConnectionState state) {
    connectionState.value = state;

    if (micState.value == 'streaming') {
      statusLabel.value = 'Listening live';
    } else if (micState.value.startsWith('healing_')) {
      final attempt = micState.value.split('_').last;
      statusLabel.value = 'Recovering mic... (Attempt $attempt/3)';
    } else {
      statusLabel.value = state.label;
    }

    isConnecting.value = state.isTransient;
    isListening.value = state == WebRTCConnectionState.connected;

    if (state == WebRTCConnectionState.connected) {
      // Start elapsed timer
      _startElapsedTimer();

      // Show ongoing foreground notification with STOP button
      ParentAudioNotificationService.showListeningNotification(
        childUid: childUid.value,
        childName: childName.value.isNotEmpty ? childName.value : 'Child',
      );

      USnackBarHelpers.successSnackBar(
        title: 'Connected',
        message: 'Listening to surroundings',
        duration: 2,
      );
    } else if (state == WebRTCConnectionState.failed) {
      hasError.value = true;
      errorMessage.value =
          'Connection failed. Child may be offline or mic permission denied.';
      _elapsedTimer?.cancel();
      ParentAudioNotificationService.hideListeningNotification();
    } else if (state == WebRTCConnectionState.disconnected) {
      hasError.value = true;
      errorMessage.value = 'Connection lost. Network may be unstable.';
      _elapsedTimer?.cancel();
      ParentAudioNotificationService.hideListeningNotification();
    } else if (state == WebRTCConnectionState.closed) {
      _elapsedTimer?.cancel();
      ParentAudioNotificationService.hideListeningNotification();
    }
  }

  void _onError(String error) {
    hasError.value = true;
    errorMessage.value = error;
    isConnecting.value = false;
    isListening.value = false;
    isPreparing.value = false;
    statusLabel.value = 'Error';
    connectionState.value = WebRTCConnectionState.failed;
    ParentAudioNotificationService.hideListeningNotification();
    debugPrint('SoundListener: ❌ $error');
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    elapsedSeconds.value = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
    });
  }

  void _updateMicStateUI(String state) {
    if (state.isEmpty) return;
    micState.value = state;
    debugPrint('SoundListener: 📊 Child mic_state = $state');

    switch (state) {
      case 'streaming':
        statusLabel.value = 'Listening live';
        isConnecting.value = false;
        isListening.value = true;
        hasError.value = false;
        break;
      case 'connecting':
        statusLabel.value = 'Connecting to child device...';
        isConnecting.value = true;
        break;
      case 'healing_1':
      case 'healing_2':
      case 'healing_3':
        final attempt = state.split('_').last;
        statusLabel.value = 'Recovering mic... (Attempt $attempt/3)';
        isConnecting.value = true;
        break;
      case 'blocked_fgs_type':
        statusLabel.value = 'Mic blocked by OS';
        _onError(
          'Microphone was blocked by Android system restrictions. '
          'Please open the CareCircle child app once on child\'s phone.',
        );
        break;
      case 'blocked_silent':
        statusLabel.value = 'Mic silent (Blocked)';
        _onError(
          'Microphone returned silent audio. '
          'Please open the CareCircle child app once to reactivate.',
        );
        break;
      case 'blocked_no_permission':
        statusLabel.value = 'Mic permission denied';
        _onError('Microphone permission has been revoked on child device.');
        break;
      case 'stopped':
        // Only trigger error if session was actively listening and child stopped it
        if (isListening.value) {
          statusLabel.value = 'Stopped by child device';
          _onError('Child device stopped the mic stream.');
        }
        break;
      default:
        break;
    }
  }

  // ============ COMPUTED GETTERS ============

  /// Formatted elapsed time (e.g., "2m 30s" or "45s")
  String get elapsedFormatted {
    final mins = elapsedSeconds.value ~/ 60;
    final secs = elapsedSeconds.value % 60;
    if (mins > 0) {
      return '${mins}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }

  /// Whether to show the "retry" button
  bool get canRetry {
    final err = hasError.value;
    return err && !isSessionActive;
  }

  /// Whether to show the "stop" button
  bool get canStop {
    final listening = isListening.value;
    final connecting = isConnecting.value;
    return isSessionActive || listening || connecting;
  }
}
