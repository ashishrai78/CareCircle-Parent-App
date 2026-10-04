import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/repositories/features/sound_listener_repository.dart';
import '../../../data/services/webrtc_audio_receiver.dart';
import '../../../data/services/webrtc_config.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/snackbars.dart';

/// 🎧 SoundListenerController — Parent-side controller for listening to child's mic
///
/// Flow:
///  1. Check internet + child online
///  2. Generate callId = "{childUid}_{timestamp}"
///  3. Write sync_mic=true + call_id to child_control/{childUid}
///  4. Start WebRTCAudioReceiver — creates offer, waits for answer
///  5. On connected: UI shows "Listening" state
///  6. On stop: clear sync_mic, stop WebRTC, cleanup Firestore
///
/// Production features:
///  ✅ Pre-flight checks (network, child online)
///  ✅ State machine with reactive updates
///  ✅ Auto-retry on transient failures
///  ✅ Connection timeout (30s)
///  ✅ Defensive stop (safe to call multiple times)
///  ✅ WillPopScope integration — stops on back press
///  ✅ Clear error messages for UI
class SoundListenerController extends GetxController {
  SoundListenerController({required this.childUid});

  /// Child's user UID (NOT call_id)
  final String childUid;

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
  final RxString statusLabel = 'Initializing...'.obs;

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

    // Wire up receiver callbacks
    _receiver.onStateChanged = _onConnectionStateChanged;
    _receiver.onError = _onError;

    // Auto-start listening when controller initializes
    startListening();
  }

  @override
  void onClose() {
    _elapsedTimer?.cancel();
    _controlSub?.cancel();
    _receiver.stop();
    super.onClose();
  }

  // ============ PUBLIC API ============

  /// Start listening to child's surroundings
  ///
  /// Pre-flight checks:
  ///  1. Internet connection
  ///  2. Child device online (heartbeat < 5 min)
  ///  3. Generate callId
  ///  4. Send sync_mic=true to child
  ///  5. Start WebRTC receiver
  Future<void> startListening() async {
    if (isSessionActive) {
      debugPrint('SoundListener: Session already active — skipping');
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
        _onError('No internet connection. Please check your network and try again.');
        return;
      }

      // ============ PRE-FLIGHT CHECK 2: Child online ============
      statusLabel.value = 'Checking child device...';
      final childOnline = await _repository.isChildOnline(childUid);
      isChildOnline.value = childOnline;

      if (!childOnline) {
        _onError(
          'Child device appears to be offline. '
          'Make sure the child\'s phone is on and connected to the internet.',
        );
        return;
      }

      // ============ STEP 1: Generate callId ============
      _currentCallId = WebRTCConfig.generateCallId(childUid);
      debugPrint('SoundListener: Generated callId = $_currentCallId');

      // ============ STEP 2: Send sync_mic=true to child ============
      isPreparing.value = false;
      statusLabel.value = 'Notifying child device...';
      await _repository.startMicListening(
        childUid: childUid,
        callId: _currentCallId!,
      );
      debugPrint('SoundListener: ✅ Wrote sync_mic=true + call_id');

      // Listen to child_control for state changes
      _controlSub = _repository.streamChildControl(childUid).listen((data) async {
        if (data == null) return;

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
          debugPrint('SoundListener: 🔄 Child auto-healed call_id: $_currentCallId -> $newCallId');
          _currentCallId = newCallId;
          statusLabel.value = 'Re-establishing audio session...';
          isConnecting.value = true;
          try {
            await _receiver.start(newCallId);
          } catch (e) {
            debugPrint('SoundListener: ❌ Failed to restart receiver on heal: $e');
            _onError('Failed to reconnect after mic recovery: $e');
          }
        }
      });

      // ============ STEP 3: Start WebRTC receiver ============
      statusLabel.value = 'Connecting to child device...';
      await _receiver.start(_currentCallId!);

      // UI will be updated via _onConnectionStateChanged callback
    } catch (e, stackTrace) {
      debugPrint('SoundListener: ❌ Start failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _onError('Failed to start listening: $e');
    }
  }

  /// Stop listening to child's surroundings
  Future<void> stopListening() async {
    debugPrint('SoundListener: Stopping session');

    // Stop elapsed timer
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    // Stop listening to child_control
    await _controlSub?.cancel();
    _controlSub = null;

    // Stop WebRTC receiver (also cleans up Firestore signaling)
    try {
      await _receiver.stop();
    } catch (e) {
      debugPrint('SoundListener: Receiver stop error: $e');
    }

    // Clean up call signaling document
    if (_currentCallId != null) {
      await _repository.cleanupCallDocument(_currentCallId!);
    }

    // Clear sync_mic flag + delete call_id from child_control
    if (_currentCallId != null) {
      try {
        await _repository.stopMicListening(childUid);
        debugPrint('SoundListener: ✅ Cleared sync_mic + call_id');
      } catch (e) {
        debugPrint('SoundListener: ⚠️ Firestore clear error: $e');
      }
    }

    // Reset state
    _currentCallId = null;
    micState.value = '';
    isListening.value = false;
    isConnecting.value = false;
    isPreparing.value = false;
    elapsedSeconds.value = 0;
    statusLabel.value = 'Stopped';
    connectionState.value = WebRTCConnectionState.closed;
  }

  /// Retry connection (after failure)
  Future<void> retry() async {
    await stopListening();
    await Future.delayed(const Duration(milliseconds: 500));
    await startListening();
  }

  /// Stop and go back (UI button handler)
  Future<void> onStopPressed() async {
    await stopListening();
    Get.back();
  }

  /// WillPopScope handler — stop on back press
  Future<bool> onWillPop() async {
    await stopListening();
    return true;
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
      USnackBarHelpers.successSnackBar(
        title: 'Connected',
        message: 'Listening to surroundings',
        duration: 2,
      );
    } else if (state == WebRTCConnectionState.failed) {
      hasError.value = true;
      errorMessage.value = 'Connection failed. Child may be offline or mic permission denied.';
      _elapsedTimer?.cancel();
    } else if (state == WebRTCConnectionState.disconnected) {
      hasError.value = true;
      errorMessage.value = 'Connection lost. Network may be unstable.';
      _elapsedTimer?.cancel();
    } else if (state == WebRTCConnectionState.closed) {
      _elapsedTimer?.cancel();
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
        if (isSessionActive) {
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
  bool get canRetry => hasError.value && !isSessionActive;

  /// Whether to show the "stop" button
  bool get canStop => isSessionActive || isConnecting.value;
}
