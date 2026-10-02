import 'dart:async';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/repositories/features/contacts_repository.dart';
import '../../../utils/popups/snackbars.dart';

class ContactsController extends GetxController {
  ContactsController({required this.childUid});

  final String childUid;
  final ContactsRepository _repository = ContactsRepository();

  final RxList<ContactModel> contacts = <ContactModel>[].obs;
  final RxList<ContactModel> filteredContacts = <ContactModel>[].obs;
  final Rx<ContactStats?> stats = Rx<ContactStats?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString error = ''.obs;
  final RxBool showStarredOnly = false.obs;

  StreamSubscription<List<ContactModel>>? _contactsSub;
  StreamSubscription<ContactStats>? _statsSub;

  @override
  void onInit() {
    super.onInit();
    _initStreams();
  }

  @override
  void onClose() {
    _contactsSub?.cancel();
    _statsSub?.cancel();
    super.onClose();
  }

  void _initStreams() {
    _contactsSub = _repository.streamContacts(childUid).listen(
      (data) {
        contacts.value = data;
        _applyFilters();
        error.value = '';
        isLoading.value = false;
      },
      onError: (err) {
        error.value = 'Error loading contacts: $err';
        isLoading.value = false;
      },
    );

    _statsSub = _repository.streamContactStats(childUid).listen(
      (data) {
        stats.value = data;
      },
      onError: (err) {
        print('Stats stream error: $err');
      },
    );
  }

  void _applyFilters() {
    var result = contacts.toList();

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((c) {
        return c.displayName.toLowerCase().contains(query) ||
            c.primaryPhone.toLowerCase().contains(query) ||
            c.phoneNumbers.any((p) => p.toLowerCase().contains(query)) ||
            c.emails.any((e) => e.toLowerCase().contains(query));
      }).toList();
    }

    if (showStarredOnly.value) {
      result = result.where((c) => c.isStarred).toList();
    }

    result.sort((a, b) {
      if (a.isStarred && !b.isStarred) return -1;
      if (!a.isStarred && b.isStarred) return 1;
      return a.displayName.compareTo(b.displayName);
    });

    filteredContacts.value = result;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void toggleStarredFilter() {
    showStarredOnly.value = !showStarredOnly.value;
    _applyFilters();
  }

  void clearSearch() {
    searchQuery.value = '';
    _applyFilters();
  }

  Future<void> requestSync() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    try {
      await _repository.requestContactsSync(childUid);
      USnackBarHelpers.successSnackBar(
        title: 'Sync Requested',
        message: 'Asked child device to send fresh contacts',
      );
    } catch (e) {
      USnackBarHelpers.errorSnackBar(
        title: 'Sync Failed',
        message: e.toString(),
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> callContact(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not make call',
      );
    }
  }

  Future<void> smsContact(String phoneNumber) async {
    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not open SMS',
      );
    }
  }

  Future<void> emailContact(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not open email',
      );
    }
  }

  int get totalContacts => contacts.length;
  int get starredCount => contacts.where((c) => c.isStarred).length;
  int get contactsWithPhoto => contacts.where((c) => c.hasPhoto).length;
  int get contactsWithEmail => contacts.where((c) => c.emails.isNotEmpty).length;

  String get lastSyncAgo => stats.value?.lastSync != null
      ? ContactModel(
          id: '',
          displayName: '',
          primaryPhone: '',
          updatedAt: stats.value!.lastSync,
          phoneNumbers: [],
          emails: [],
        ).lastSyncAgo
      : 'Never';

  bool get hasContacts => contacts.isNotEmpty;
}
