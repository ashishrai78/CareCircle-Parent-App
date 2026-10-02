import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/installed_app_model.dart';
import '../../../data/repositories/features/installed_apps_repository.dart';
import '../../../utils/popups/snackbars.dart';
import 'dart:async';

/// 📱 InstalledAppsController — manages installed apps list
///
/// Production improvements:
///  ✅ Takes childUid via constructor
///  ✅ Uses repository pattern
///  ✅ Real-time stream (auto-updates when child syncs)
///  ✅ Search by name OR package name
///  ✅ Filter by category
///  ✅ Sort by name (A-Z) or install date (newest first)
///  ✅ Decompresses base64 icons to Uint8List
class InstalledAppsController extends GetxController {
  InstalledAppsController({required this.childUid});

  final String childUid;

  final InstalledAppsRepository _repository = InstalledAppsRepository();

  // ============ Reactive State ============
  final RxList<InstalledAppModel> installedApps = <InstalledAppModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;

  // Search & Filter
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString sortBy = 'name'.obs; // 'name' or 'installedAt'
  final TextEditingController searchController = TextEditingController();

  StreamSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    _initStream();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    searchController.dispose();
    super.onClose();
  }

  /// Initialize real-time stream
  Future<void> _initStream() async {
    try {
      _subscription = _repository.streamInstalledApps(childUid).listen(
        (collection) {
          if (collection == null) {
            installedApps.clear();
            error.value = 'No apps data available';
          } else {
            installedApps.value = collection.apps;
            error.value = '';
          }
          isLoading.value = false;
          isRefreshing.value = false;
        },
        onError: (err) {
          error.value = 'Failed to load installed apps: $err';
          isLoading.value = false;
          isRefreshing.value = false;
        },
      );
    } catch (e) {
      error.value = 'Failed to connect: $e';
      isLoading.value = false;
    }
  }

  /// Manual refresh
  Future<void> refreshData() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    try {
      // Re-fetch one-time
      final collection = await _repository.getInstalledApps(childUid);
      if (collection != null) {
        installedApps.value = collection.apps;
        error.value = '';
      }
      USnackBarHelpers.successSnackBar(
        title: 'Refreshed',
        message: '${installedApps.length} apps loaded',
      );
    } catch (e) {
      USnackBarHelpers.errorSnackBar(
        title: 'Refresh Failed',
        message: e.toString(),
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  // ============ Computed Getters ============

  int get totalApps => installedApps.length;

  /// Apps filtered by search query + category, sorted by sortBy
  List<InstalledAppModel> get filteredApps {
    var result = installedApps.toList();

    // Filter by category
    if (selectedCategory.value != 'All') {
      result = result
          .where((app) =>
              app.category.toLowerCase() == selectedCategory.value.toLowerCase())
          .toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((app) {
        return app.name.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
      }).toList();
    }

    // Sort
    if (sortBy.value == 'name') {
      result.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (sortBy.value == 'installedAt') {
      result.sort((a, b) => b.installedAt.compareTo(a.installedAt));
    }

    return result;
  }

  /// Get unique categories from installed apps
  List<String> get categories {
    final cats = installedApps.map((a) => a.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  /// Get apps count by category
  Map<String, int> get appsByCategory {
    final counts = <String, int>{};
    for (final app in installedApps) {
      counts[app.category] = (counts[app.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Recently installed apps (< 7 days)
  List<InstalledAppModel> get recentlyInstalled {
    return installedApps.where((a) => a.isRecentlyInstalled).toList()
      ..sort((a, b) => b.installedAt.compareTo(a.installedAt));
  }

  // ============ Actions ============

  void updateSearch(String query) => searchQuery.value = query;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  void selectCategory(String category) => selectedCategory.value = category;

  void toggleSortBy() {
    sortBy.value = sortBy.value == 'name' ? 'installedAt' : 'name';
  }

  // ============ UI Helpers ============

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'game':
        return Icons.sports_esports;
      case 'social':
        return Icons.people;
      case 'audio':
      case 'music':
        return Icons.music_note;
      case 'video':
        return Icons.play_circle;
      case 'image':
      case 'photo':
        return Icons.photo_camera;
      case 'productivity':
        return Icons.work;
      case 'accessibility':
        return Icons.accessibility;
      case 'maps':
        return Icons.map;
      case 'news':
        return Icons.newspaper;
      default:
        return Icons.android;
    }
  }

  Color getCategoryColor(String category) {
    const colors = {
      'game': Color(0xFF9C27B0),
      'social': Color(0xFF2196F3),
      'audio': Color(0xFFFF9800),
      'video': Color(0xFFF44336),
      'image': Color(0xFFE91E63),
      'productivity': Color(0xFF3F51B5),
      'accessibility': Color(0xFF009688),
      'maps': Color(0xFF4CAF50),
      'news': Color(0xFF607D8B),
    };
    return colors[category.toLowerCase()] ?? const Color(0xFF607D8B);
  }
}


