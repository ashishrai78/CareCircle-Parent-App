import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 🔔 ParentAudioNotificationService
///
/// Bridge between Flutter and Android native ParentAudioService.
/// Shows ongoing notification in notification bar when listening to surroundings.
/// Handles STOP button click directly from the notification bar.
class ParentAudioNotificationService {
  static const MethodChannel _channel =
      MethodChannel('carecircle_parent_audio_channel');

  static VoidCallback? _onStopPressedCallback;
  static bool _handlerInitialized = false;

  /// Initialize listener for native notification actions
  static void initialize({required VoidCallback onStopPressed}) {
    _onStopPressedCallback = onStopPressed;

    if (!_handlerInitialized) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onNotificationStopPressed') {
          debugPrint('ParentAudioNotificationService: ⏹ Notification STOP action received');
          _onStopPressedCallback?.call();
        }
      });
      _handlerInitialized = true;
    }
  }

  /// Show ongoing notification with STOP action button
  static Future<void> showListeningNotification({
    required String childUid,
    String? childName,
  }) async {
    try {
      await _channel.invokeMethod('startAudioNotification', {
        'childUid': childUid,
        'childName': childName ?? 'Child',
      });
      debugPrint('ParentAudioNotificationService: ✅ Notification shown for $childName');
    } catch (e) {
      debugPrint('ParentAudioNotificationService: ⚠️ Failed to show notification: $e');
    }
  }

  /// Dismiss notification and stop foreground service
  static Future<void> hideListeningNotification() async {
    try {
      await _channel.invokeMethod('stopAudioNotification');
      debugPrint('ParentAudioNotificationService: ✅ Notification dismissed');
    } catch (e) {
      debugPrint('ParentAudioNotificationService: ⚠️ Failed to hide notification: $e');
    }
  }
}

