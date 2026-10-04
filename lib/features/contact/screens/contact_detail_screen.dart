import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/popups/snackbars.dart';
import '../controllers/contacts_controller.dart';
import '../../../data/models/contact_model.dart';

class ContactDetailScreen extends StatelessWidget {
  const ContactDetailScreen({
    super.key,
    required this.childUid,
    required this.contact,
  });

  final String childUid;
  final ContactModel contact;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ContactsController(childUid: childUid));

    return Scaffold(
      backgroundColor: UColors.light,
      appBar: AppBar(
        title: const Text('Contact Details'),
        actions: [
          IconButton(
            icon: Icon(
              contact.isStarred ? Icons.star : Icons.star_border,
              color: contact.isStarred ? UColors.warning : null,
            ),
            onPressed: () {
              USnackBarHelpers.infoSnackBar(
                title: 'Starred',
                message: contact.isStarred
                    ? 'This contact is starred on child device'
                    : 'Not starred',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(USizes.md),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: USizes.lg),
            _buildQuickActions(controller),
            const SizedBox(height: USizes.lg),
            if (contact.phoneNumbers.isNotEmpty) ...[
              _buildSection(
                title: 'Phone Numbers',
                icon: Icons.phone,
                children: contact.phoneNumbers.map((phone) {
                  final index = contact.phoneNumbers.indexOf(phone);
                  final type = index == 0
                      ? contact.primaryPhoneType ?? 'Phone'
                      : 'Phone ${index + 1}';
                  return _buildListTile(
                    icon: Icons.call,
                    title: phone,
                    subtitle: type,
                    onTap: () => controller.callContact(phone),
                    trailingIcon: Icons.call,
                    trailingColor: UColors.success,
                  );
                }).toList(),
              ),
              const SizedBox(height: USizes.md),
            ],
            if (contact.emails.isNotEmpty) ...[
              _buildSection(
                title: 'Email Addresses',
                icon: Icons.email,
                children: contact.emails.map((email) {
                  return _buildListTile(
                    icon: Icons.email,
                    title: email,
                    subtitle: 'Email',
                    onTap: () => controller.emailContact(email),
                    trailingIcon: Icons.send,
                    trailingColor: UColors.accent,
                  );
                }).toList(),
              ),
              const SizedBox(height: USizes.md),
            ],
            _buildSection(
              title: 'Additional Info',
              icon: Icons.info,
              children: [
                _buildInfoRow('Contact ID', contact.id),
                _buildInfoRow('Phone Count', '${contact.phoneCount}'),
                _buildInfoRow('Email Count', '${contact.emailCount}'),
                _buildInfoRow('Has Photo', contact.hasPhoto ? 'Yes' : 'No'),
                _buildInfoRow('Starred', contact.isStarred ? 'Yes' : 'No'),
                _buildInfoRow('Last Sync', contact.lastSyncAgo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.lg),
      color: UColors.white,
      showShadow: true,
      borderRadius: USizes.cardRadiusLg,
      child: Column(
        children: [
          if (contact.hasPhoto)
            CircleAvatar(
              radius: 50,
              backgroundColor: Color(contact.avatarColor),
              backgroundImage: MemoryImage(
                base64Decode(contact.photoBase64!),
              ),
            )
          else
            CircleAvatar(
              radius: 50,
              backgroundColor: Color(contact.avatarColor),
              child: Text(
                contact.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                ),
              ),
            ),
          const SizedBox(height: USizes.md),
          Text(
            contact.displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: UColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (contact.primaryPhone.isNotEmpty) ...[
            const SizedBox(height: USizes.xs),
            Text(
              contact.primaryPhone,
              style: TextStyle(
                fontSize: 14,
                color: UColors.textSecondary,
              ),
            ),
          ],
          if (contact.primaryPhoneType != null) ...[
            const SizedBox(height: USizes.xs),
            URoundedContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: USizes.md,
                vertical: 4,
              ),
              color: UColors.primary.withValues(alpha: 0.1),
              borderRadius: USizes.borderRadiusSm,
              child: Text(
                contact.primaryPhoneType!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: UColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(ContactsController controller) {
    return Row(
      children: [
        if (contact.primaryPhone.isNotEmpty) ...[
          Expanded(
            child: _buildActionButton(
              icon: Icons.call,
              label: 'Call',
              color: UColors.success,
              onTap: () => controller.callContact(contact.primaryPhone),
            ),
          ),
          const SizedBox(width: USizes.sm),
          Expanded(
            child: _buildActionButton(
              icon: Icons.message,
              label: 'SMS',
              color: UColors.accent,
              onTap: () => controller.smsContact(contact.primaryPhone),
            ),
          ),
        ],
        if (contact.emails.isNotEmpty) ...[
          const SizedBox(width: USizes.sm),
          Expanded(
            child: _buildActionButton(
              icon: Icons.email,
              label: 'Email',
              color: UColors.warning,
              onTap: () => controller.emailContact(contact.emails.first),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: URoundedContainer(
        padding: const EdgeInsets.symmetric(vertical: USizes.md),
        color: color.withValues(alpha: 0.1),
        borderRadius: USizes.borderRadiusMd,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.md),
      color: UColors.white,
      showShadow: true,
      borderRadius: USizes.cardRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: UColors.primary),
              const SizedBox(width: USizes.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: UColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: USizes.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData trailingIcon,
    required Color trailingColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: UColors.textSecondary, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: UColors.textTertiary,
        ),
      ),
      trailing: Icon(trailingIcon, color: trailingColor, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: UColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: UColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
