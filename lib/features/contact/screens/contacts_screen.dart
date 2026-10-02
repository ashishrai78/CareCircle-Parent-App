import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/contacts_controller.dart';
import '../../../data/models/contact_model.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({
    super.key,
    required this.childUid,
    this.childName,
  });

  final String childUid;
  final String? childName;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late final ContactsController controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ContactsController(childUid: widget.childUid));
  }

  @override
  void dispose() {
    _searchController.dispose();
    Get.delete<ContactsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UColors.light,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.childName != null
                  ? '${widget.childName}\'s Contacts'
                  : 'Contacts',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Obx(() => Text(
                  controller.hasContacts
                      ? '${controller.totalContacts} contacts • Last sync: ${controller.lastSyncAgo}'
                      : 'No contacts yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: UColors.textSecondary,
                  ),
                )),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoading();
              }
              if (controller.error.isNotEmpty &&
                  !controller.hasContacts) {
                return _buildError();
              }
              if (!controller.hasContacts) {
                return _buildEmpty();
              }
              if (controller.filteredContacts.isEmpty) {
                return _buildNoSearchResults();
              }
              return _buildContactsList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(USizes.md),
      padding: const EdgeInsets.symmetric(horizontal: USizes.md),
      decoration: BoxDecoration(
        color: UColors.white,
        borderRadius: BorderRadius.circular(USizes.borderRadiusLg),
        boxShadow: [
          BoxShadow(
            color: UColors.dark.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: UColors.textSecondary, size: 20),
          const SizedBox(width: USizes.sm),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: controller.updateSearch,
              decoration: const InputDecoration(
                hintText: 'Search name, phone, or email...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                controller.clearSearch();
              },
            ),
          IconButton(
            icon: Obx(() => Icon(
                  Icons.star,
                  size: 20,
                  color: controller.showStarredOnly.value
                      ? UColors.warning
                      : UColors.textTertiary,
                )),
            onPressed: controller.toggleStarredFilter,
            tooltip: 'Starred only',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Obx(() {
      if (!controller.hasContacts) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: USizes.md),
        child: Row(
          children: [
            _buildStatChip(
              icon: Icons.people,
              label: 'Total',
              value: '${controller.totalContacts}',
              color: UColors.primary,
            ),
            const SizedBox(width: USizes.sm),
            _buildStatChip(
              icon: Icons.star,
              label: 'Starred',
              value: '${controller.starredCount}',
              color: UColors.warning,
            ),
            const SizedBox(width: USizes.sm),
            _buildStatChip(
              icon: Icons.photo,
              label: 'Photos',
              value: '${controller.contactsWithPhoto}',
              color: UColors.accent,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: URoundedContainer(
        padding: const EdgeInsets.all(USizes.sm),
        color: color.withValues(alpha: 0.08),
        borderRadius: USizes.borderRadiusMd,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$value $label',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(USizes.md),
      itemCount: controller.filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = controller.filteredContacts[index];
        return _buildContactTile(contact);
      },
    );
  }

  Widget _buildContactTile(ContactModel contact) {
    return URoundedContainer(
      margin: const EdgeInsets.only(bottom: USizes.sm),
      color: UColors.white,
      showShadow: true,
      borderRadius: USizes.cardRadiusMd,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: USizes.md,
          vertical: USizes.xs,
        ),
        leading: _buildAvatar(contact),
        title: Row(
          children: [
            if (contact.isStarred)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.star, size: 14, color: UColors.warning),
              ),
            Expanded(
              child: Text(
                contact.displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: UColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.primaryPhone.isNotEmpty)
              Text(
                contact.primaryPhone,
                style: TextStyle(
                  fontSize: 12,
                  color: UColors.textSecondary,
                ),
              ),
            if (contact.primaryPhoneType != null)
              Text(
                contact.primaryPhoneType!,
                style: TextStyle(
                  fontSize: 10,
                  color: UColors.textTertiary,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.primaryPhone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.call, size: 18),
                color: UColors.success,
                onPressed: () => controller.callContact(contact.primaryPhone),
                tooltip: 'Call',
              ),
            if (contact.primaryPhone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.message, size: 18),
                color: UColors.accent,
                onPressed: () => controller.smsContact(contact.primaryPhone),
                tooltip: 'SMS',
              ),
          ],
        ),
        onTap: () => Get.to(() => ContactDetailScreen(
              childUid: widget.childUid,
              contact: contact,
            )),
      ),
    );
  }

  Widget _buildAvatar(ContactModel contact) {
    if (contact.hasPhoto) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Color(contact.avatarColor),
        backgroundImage: MemoryImage(
          base64Decode(contact.photoBase64!),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: Color(contact.avatarColor),
      child: Text(
        contact.initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: UColors.primary),
          const SizedBox(height: USizes.md),
          const Text(
            'Loading contacts...',
            style: TextStyle(color: UColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: UColors.error),
            const SizedBox(height: USizes.md),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: USizes.xs),
            Text(
              controller.error.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: UColors.textSecondary),
            ),
            const SizedBox(height: USizes.lg),
            ElevatedButton.icon(
              onPressed: controller.requestSync,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts_outlined, size: 64, color: UColors.textTertiary),
            const SizedBox(height: USizes.md),
            const Text(
              'No Contacts Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: USizes.xs),
            const Text(
              'Request the child device to sync contacts',
              textAlign: TextAlign.center,
              style: TextStyle(color: UColors.textSecondary),
            ),
            const SizedBox(height: USizes.lg),
            ElevatedButton.icon(
              onPressed: controller.requestSync,
              icon: const Icon(Icons.sync),
              label: const Text('Request Sync'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: UColors.textTertiary),
          const SizedBox(height: USizes.md),
          const Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: USizes.xs),
          Text(
            'No contacts match "${controller.searchQuery.value}"',
            style: const TextStyle(color: UColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
