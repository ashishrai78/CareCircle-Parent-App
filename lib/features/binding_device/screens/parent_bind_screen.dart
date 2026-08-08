import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controller/parent_bind_controller.dart';

class ParentBindScreen extends StatelessWidget {
  final String parentUid;

  ParentBindScreen({super.key, required this.parentUid});

  final TextEditingController codeController = TextEditingController();
  final ParentBindController controller = Get.put(ParentBindController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Link Device", style: Theme.of(context).textTheme.headlineSmall!.apply(color: UColors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8))),
        centerTitle: true,
        backgroundColor: UColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(USizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with illustration
            _buildHeader(),

            const SizedBox(height: USizes.spaceBtwSections),

            // Instruction Text
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: USizes.md,
                  vertical: USizes.sm,
                ),
                decoration: BoxDecoration(
                  color: UColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text("Enter the code shown on your child's device",
                  style: Theme.of(context).textTheme.labelMedium!.apply(color: UColors.primary)
                ),
              ),
            ),

            const SizedBox(height: USizes.spaceBtwSections),

            // Code Input Card
            _buildCodeInputCard(context),

            const SizedBox(height: USizes.spaceBtwSections * 1.5),

            // QR Alternative Option
            _buildQROption(),

            const SizedBox(height: USizes.spaceBtwSections * 2),

            // Link Button
            _buildLinkButton(),

            const SizedBox(height: USizes.spaceBtwSections),

            // Help Text
            _buildHelpText(),
          ],
        ),
      ),
    );
  }


  /////==================Widgets====================

  //// Header
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  UColors.primary,
                  UColors.primary.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: UColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.link_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: USizes.md),
          const Text(
            'Connect with Child',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  //// Code InputCard
  Widget _buildCodeInputCard(BuildContext context) {
    return URoundedContainer(
      color: Colors.white,
      border: true,
      child: Padding(
        padding: const EdgeInsets.all(USizes.lg),
        child: Column(
          children: [
            // Code Label
            Row(
              children: [
                // Icon
                const Icon(Icons.qr_code_2, size: 20, color: UColors.primary,),
                const SizedBox(width: 8),
                Text('Child Code',
                  style: Theme.of(context).textTheme.headlineSmall
                ),
              ],
            ),

            const SizedBox(height: USizes.md),

            // TextField with modern design
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: UColors.primary,
              ),
              decoration: InputDecoration(
                hintText: '••••••',
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: UColors.grey.withOpacity(0.5),
                ),
                filled: true,
                fillColor: UColors.primary.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(USizes.cardRadiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(USizes.cardRadiusMd),
                  borderSide: BorderSide(
                    color: UColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(USizes.cardRadiusMd),
                  borderSide: const BorderSide(
                    color: UColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: USizes.md,
                  vertical: USizes.lg,
                ),
              ),
            ),

            const SizedBox(height: USizes.md),

            // Helper text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Code is 6 digits',
                  style: TextStyle(
                    fontSize: 12,
                    color: UColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //// Scan QR And Connect Device
  Widget _buildQROption() {
    return URoundedContainer(
      color: Colors.white,
      border: true,
      child: Padding(
        padding: const EdgeInsets.all(USizes.md),
        child: Row(
          children: [
            // QR Icon
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: UColors.primary,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: USizes.md),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use camera to scan QR code from monitoring device',
                    style: TextStyle(
                      fontSize: 12,
                      color: UColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: UColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: UColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //// Link Button
  Widget _buildLinkButton() {
    return Obx(() {
      final isLoading = controller.isLoading.value;

      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
            await controller.bindParentToChild(codeController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: UColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(USizes.buttonRadius),
            ),
          ),
          child: isLoading
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: USizes.sm),
              const Text(
                'Linking...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          )
              : const Text(
            'Link Device',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  //// For Help Text Button
  Widget _buildHelpText() {
    return Column(
      children: [
        Center(
          child: TextButton.icon(
            onPressed: () {
              // Help action
            },
            icon: const Icon(
              Icons.help_outline,
              size: 16,
              color: UColors.primary,
            ),
            label: const Text(
              'Need help connecting?',
              style: TextStyle(
                fontSize: 13,
                color: UColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: USizes.sm),
      ],
    );
  }

/////==================Widgets====================

}