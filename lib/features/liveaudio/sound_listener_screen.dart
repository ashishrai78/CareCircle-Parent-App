import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/texts.dart';
import '../../data/services/webrtc_config.dart';
import 'controller/sound_listener_controller.dart';

/// 🎧 SoundListenerScreen — Parent listens to child's surroundings in real-time
///
/// Features:
///  ✅ Pre-flight checks (network, child online)
///  ✅ Live connection state visualization (animated)
///  ✅ Elapsed timer (how long listening)
///  ✅ Clear instructions & warnings (audio quality, network, privacy)
///  ✅ Retry on failure
///  ✅ Defensive stop (back press also stops)
///  ✅ Privacy notice (child sees notification)
///  ✅ Tips for better audio quality
class SoundListenerScreen extends StatefulWidget {
  const SoundListenerScreen({
    super.key,
    required this.childUid,
    this.childName,
  });

  final String childUid;
  final String? childName;

  @override
  State<SoundListenerScreen> createState() => _SoundListenerScreenState();
}

class _SoundListenerScreenState extends State<SoundListenerScreen>
    with TickerProviderStateMixin {
  late final SoundListenerController controller;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    controller = Get.put(SoundListenerController(childUid: widget.childUid));

    // Pulse animation for "listening" state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    controller.stopListening();
    Get.delete<SoundListenerController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await controller.onWillPop();
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: UColors.light,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.childName != null
                    ? 'Listening to ${widget.childName}'
                    : 'Listen to Surroundings',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Obx(() => Text(
                    controller.statusLabel.value,
                    style: TextStyle(
                      fontSize: 11,
                      color: UColors.textSecondary,
                    ),
                  )),
            ],
          ),
          actions: [
            Obx(() {
              if (controller.canStop) {
                return IconButton(
                  icon: const Icon(Icons.stop_circle, color: UColors.error),
                  tooltip: 'Stop',
                  onPressed: controller.onStopPressed,
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(USizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main visual area (animated mic / status)
              _buildMainVisual(),
              const SizedBox(height: USizes.lg),

              // Status + elapsed time
              _buildStatusSection(),
              const SizedBox(height: USizes.lg),

              // Error message (if any)
              Obx(() => controller.hasError.value
                  ? _buildErrorCard()
                  : const SizedBox.shrink()),
              Obx(() => controller.hasError.value
                  ? const SizedBox(height: USizes.lg)
                  : const SizedBox.shrink()),

              // Instructions / Tips card
              _buildInstructionsCard(),
              const SizedBox(height: USizes.md),

              // Privacy notice
              _buildPrivacyNotice(),
              const SizedBox(height: USizes.lg),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ============ MAIN VISUAL ============

  Widget _buildMainVisual() {
    return Obx(() {
      final state = controller.connectionState.value;
      final isListening = state == WebRTCConnectionState.connected;
      final isConnecting = state.isTransient;
      final hasError = state == WebRTCConnectionState.failed ||
          state == WebRTCConnectionState.disconnected;

      // Start/stop pulse animation based on state
      if (isListening && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      } else if (!isListening && _pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }

      return SizedBox(
        height: 280,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing rings (only when listening)
              if (isListening) ...[
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 180 * _pulseAnimation.value,
                      height: 180 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: UColors.recording.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 140 * _pulseAnimation.value,
                      height: 140 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: UColors.recording.withValues(alpha: 0.1),
                      ),
                    );
                  },
                ),
              ],

              // Main circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isListening
                        ? [UColors.recording, UColors.error]
                        : isConnecting
                            ? [UColors.warning, UColors.primary]
                            : hasError
                                ? [UColors.error, UColors.error.withValues(alpha: 0.7)]
                                : [UColors.primary, UColors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isListening
                              ? UColors.recording
                              : UColors.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isListening
                      ? Icons.hearing
                      : isConnecting
                          ? Icons.hourglass_top
                          : hasError
                              ? Icons.error_outline
                              : Icons.mic_none_rounded,
                  size: 56,
                  color: UColors.textWhite,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ============ STATUS SECTION ============

  Widget _buildStatusSection() {
    return Obx(() {
      final state = controller.connectionState.value;
      final isListening = state == WebRTCConnectionState.connected;

      return Container(
        padding: const EdgeInsets.all(USizes.lg),
        decoration: BoxDecoration(
          color: UColors.white,
          borderRadius: BorderRadius.circular(USizes.cardRadiusLg),
          boxShadow: [
            BoxShadow(
              color: UColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status label
            Text(
              controller.statusLabel.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isListening
                    ? UColors.success
                    : controller.hasError.value
                        ? UColors.error
                        : UColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: USizes.sm),

            // Elapsed time (only when listening)
            if (isListening) ...[
              Text(
                controller.elapsedFormatted,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: UColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: USizes.xs),
              Text(
                'Listening time',
                style: TextStyle(
                  fontSize: 12,
                  color: UColors.textSecondary,
                ),
              ),
            ],

            // Subtitle (current action)
            if (!isListening && !controller.hasError.value) ...[
              const SizedBox(height: USizes.xs),
              Text(
                _getSubtitleForState(state),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: UColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _getSubtitleForState(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.idle:
        return 'Tap "Start Listening" to begin';
      case WebRTCConnectionState.initializing:
        return 'Preparing connection...';
      case WebRTCConnectionState.creatingOffer:
        return 'Creating WebRTC offer...';
      case WebRTCConnectionState.waitingForAnswer:
        return 'Waiting for child device to respond...\nThis may take up to 30 seconds.';
      case WebRTCConnectionState.connecting:
        return 'Establishing connection...';
      case WebRTCConnectionState.connected:
        return '';
      case WebRTCConnectionState.failed:
        return 'Connection failed. Please retry.';
      case WebRTCConnectionState.disconnected:
        return 'Connection lost. Please retry.';
      case WebRTCConnectionState.closed:
        return 'Session ended.';
    }
  }

  // ============ ERROR CARD ============

  Widget _buildErrorCard() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(USizes.md),
        decoration: BoxDecoration(
          color: UColors.errorBg,
          borderRadius: BorderRadius.circular(USizes.cardRadiusMd),
          border: Border.all(color: UColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: UColors.error, size: 20),
                const SizedBox(width: USizes.xs),
                const Text(
                  'Connection Error',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: UColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: USizes.xs),
            Text(
              controller.errorMessage.value,
              style: const TextStyle(
                fontSize: 13,
                color: UColors.textPrimary,
              ),
            ),
            const SizedBox(height: USizes.sm),
            // Troubleshooting tips
            const Text(
              'Troubleshooting:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: UColors.textSecondary,
              ),
            ),
            const SizedBox(height: USizes.xs),
            _buildTip('Ensure both devices have stable internet'),
            _buildTip('Check if child device is online (battery > 0%)'),
            _buildTip('Verify mic permission is granted on child device'),
            _buildTip('Try again in a few seconds'),
          ],
        ),
      );
    });
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: USizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: UColors.error)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: UColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ INSTRUCTIONS / TIPS ============

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(USizes.md),
      decoration: BoxDecoration(
        color: UColors.infoBg,
        borderRadius: BorderRadius.circular(USizes.cardRadiusMd),
        border: Border.all(color: UColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: UColors.info, size: 20),
              const SizedBox(width: USizes.xs),
              const Text(
                'Before You Listen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: UColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: USizes.sm),
          _buildInstructionItem(
            icon: Icons.network_check,
            text:
                'Network Quality: Audio quality depends on both devices\' internet. Wi-Fi recommended for best results.',
          ),
          _buildInstructionItem(
            icon: Icons.volume_down,
            text:
                'Audio Quality: Background noise may be present. Audio may sound muffled or low — this is normal for ambient listening.',
          ),
          _buildInstructionItem(
            icon: Icons.timer,
            text:
                'Connection Time: First connection may take 5–30 seconds as WebRTC establishes a peer-to-peer link.',
          ),
          _buildInstructionItem(
            icon: Icons.battery_alert,
            text:
                'Battery Drain: Prolonged listening drains child\'s battery faster. Limit sessions to 5–10 minutes.',
          ),
          _buildInstructionItem(
            icon: Icons.phonelink_lock,
            text:
                'Privacy Notice: Child device shows a persistent notification during listening. They will know mic is active.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: USizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: UColors.info),
          const SizedBox(width: USizes.xs),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: UColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ PRIVACY NOTICE ============

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(USizes.md),
      decoration: BoxDecoration(
        color: UColors.warningBg,
        borderRadius: BorderRadius.circular(USizes.cardRadiusMd),
        border: Border.all(color: UColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip, color: UColors.warning, size: 20),
          const SizedBox(width: USizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Privacy Notice',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: UColors.warning,
                  ),
                ),
                SizedBox(height: USizes.xs),
                Text(
                  'This feature activates the microphone on your child\'s device. '
                  'Use responsibly and only when needed for safety. '
                  'The child will see a notification indicating mic is active.',
                  style: TextStyle(
                    fontSize: 12,
                    color: UColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ ACTION BUTTONS ============

  Widget _buildActionButtons() {
    return Obx(() {
      final canStop = controller.canStop;
      final canRetry = controller.canRetry;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Retry button (only on error)
          if (canRetry) ...[
            ElevatedButton.icon(
              onPressed: controller.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: USizes.md),
              ),
            ),
            const SizedBox(height: USizes.sm),
          ],

          // Stop button (when session active)
          if (canStop) ...[
            ElevatedButton.icon(
              onPressed: controller.onStopPressed,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Listening'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UColors.error,
                foregroundColor: UColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: USizes.md),
              ),
            ),
          ],

          // Back button (always available)
          if (!canStop) ...[
            OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: USizes.md),
              ),
            ),
          ],
        ],
      );
    });
  }
}
