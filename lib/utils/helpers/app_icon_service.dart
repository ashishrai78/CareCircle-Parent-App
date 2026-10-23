import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

/// 🎯 AppIconService — High-performance icon resolver for Parent App
///
/// Resolution hierarchy:
/// 1. In-memory cache (Instant)
/// 2. Local device native PackageManager via MethodChannel (Instant, works if app installed on parent device)
/// 3. Persistent disk cache via GetStorage (Instant)
/// 4. Google Play Store official CDN icon (og:image) (Cached forever)
/// 5. Smart fallback: Brand/System Icon + Initials Avatar with branded colors
class AppIconService {
  AppIconService._();
  static final AppIconService instance = AppIconService._();

  static const MethodChannel _channel = MethodChannel('app_info_channel');
  static const String _storageBoxName = 'carecircle_app_icons_box';

  final Map<String, String?> _iconUrlCache = {};
  final Map<String, Uint8List?> _nativeIconCache = {};
  final Map<String, Future<String?>> _inFlightFetches = {};

  GetStorage? _storage;
  GetStorage get _box {
    _storage ??= GetStorage(_storageBoxName);
    return _storage!;
  }

  /// Known popular app brand colors
  static final Map<String, Color> _brandColors = {
    'whatsapp': const Color(0xFF25D366),
    'instagram': const Color(0xFFE4405F),
    'youtube': const Color(0xFFFF0000),
    'facebook': const Color(0xFF1877F2),
    'snapchat': const Color(0xFFFFCC00),
    'spotify': const Color(0xFF1DB954),
    'netflix': const Color(0xFFE50914),
    'telegram': const Color(0xFF24A1DE),
    'tiktok': const Color(0xFF111111),
    'twitter': const Color(0xFF1DA1F2),
    'chrome': const Color(0xFF4285F4),
    'gmail': const Color(0xFFEA4335),
    'maps': const Color(0xFF34A853),
    'photos': const Color(0xFFFF6D00),
    'phonepe': const Color(0xFF5F259F),
    'paytm': const Color(0xFF00B9F5),
    'gpay': const Color(0xFF1A73E8),
    'discord': const Color(0xFF5865F2),
    'reddit': const Color(0xFFFF4500),
    'pinterest': const Color(0xFFE60023),
    'linkedin': const Color(0xFF0A66C2),
    'amazon': const Color(0xFFFF9900),
    'roblox': const Color(0xFF111111),
  };

  /// Vibrant fallback palette for apps without specific brand color
  static const List<Color> _palette = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
  ];

  /// Try to get native icon from parent device's PackageManager
  Future<Uint8List?> getNativeIcon(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    if (_nativeIconCache.containsKey(packageName)) {
      return _nativeIconCache[packageName];
    }

    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'getAppIcon',
        {'packageName': packageName},
      );
      if (bytes != null && bytes.isNotEmpty) {
        _nativeIconCache[packageName] = bytes;
        return bytes;
      }
    } catch (_) {}

    _nativeIconCache[packageName] = null;
    return null;
  }

  /// Get Google Play Store official icon URL (cached in GetStorage)
  Future<String?> getIconUrl(String packageName) async {
    if (packageName.isEmpty) return null;

    // 1. Check in-memory cache
    if (_iconUrlCache.containsKey(packageName)) {
      return _iconUrlCache[packageName];
    }

    // 2. Check local disk cache (GetStorage)
    try {
      if (_box.hasData(packageName)) {
        final cached = _box.read<String>(packageName);
        if (cached == 'NOT_FOUND') {
          _iconUrlCache[packageName] = null;
          return null;
        }
        if (cached != null && cached.startsWith('http')) {
          _iconUrlCache[packageName] = cached;
          return cached;
        }
      }
    } catch (_) {}

    // 3. System apps without Play Store presence: quick skip
    if (_isSystemAppPackage(packageName)) {
      _iconUrlCache[packageName] = null;
      try {
        _box.write(packageName, 'NOT_FOUND');
      } catch (_) {}
      return null;
    }

    // 4. In-flight request deduplication
    if (_inFlightFetches.containsKey(packageName)) {
      return _inFlightFetches[packageName];
    }

    // 5. Scrape og:image from Google Play Store web page
    final fetchFuture = _fetchFromPlayStore(packageName);
    _inFlightFetches[packageName] = fetchFuture;

    final url = await fetchFuture;
    _inFlightFetches.remove(packageName);
    return url;
  }

  Future<String?> _fetchFromPlayStore(String packageName) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName&hl=en',
      );
      final request = await client.getUrl(uri);
      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final match = RegExp(
          r'<meta property="og:image" content="([^"]+)"',
        ).firstMatch(body);

        if (match != null) {
          var iconUrl = match.group(1);
          if (iconUrl != null && iconUrl.startsWith('http')) {
            // High-res & clean
            _iconUrlCache[packageName] = iconUrl;
            try {
              _box.write(packageName, iconUrl);
            } catch (_) {}
            return iconUrl;
          }
        }
      }

      // Mark as not found so we don't query repeatedly
      _iconUrlCache[packageName] = null;
      try {
        _box.write(packageName, 'NOT_FOUND');
      } catch (_) {}
      return null;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  bool _isSystemAppPackage(String pkg) {
    final lower = pkg.toLowerCase();
    if (lower.startsWith('com.android.internal') ||
        lower.startsWith('com.android.systemui') ||
        lower.startsWith('com.android.settings') ||
        lower.startsWith('com.sec.android.app.settings') ||
        lower.startsWith('com.samsung.android.app.settings')) {
      return true;
    }
    return false;
  }

  /// Get fallback icon for system apps or failed downloads
  IconData getFallbackIcon(String packageName, {String? category}) {
    final lower = packageName.toLowerCase();

    if (lower.contains('setting')) return Icons.settings;
    if (lower.contains('dialer') || lower.contains('phone') || lower.contains('call')) {
      return Icons.phone;
    }
    if (lower.contains('message') || lower.contains('sms') || lower.contains('mms')) {
      return Icons.chat_bubble;
    }
    if (lower.contains('camera')) return Icons.camera_alt;
    if (lower.contains('gallery') || lower.contains('photo')) {
      return Icons.photo_library;
    }
    if (lower.contains('file') || lower.contains('explorer')) {
      return Icons.folder;
    }
    if (lower.contains('clock') || lower.contains('alarm')) {
      return Icons.access_time;
    }
    if (lower.contains('contact')) return Icons.contacts;
    if (lower.contains('calculat')) return Icons.calculate;
    if (lower.contains('calendar')) return Icons.calendar_today;
    if (lower.contains('chrome') || lower.contains('browser')) {
      return Icons.public;
    }
    if (lower.contains('music') || lower.contains('audio') || lower.contains('sound')) {
      return Icons.music_note;
    }
    if (lower.contains('video') || lower.contains('player')) {
      return Icons.play_circle_fill;
    }
    if (lower.contains('game')) return Icons.sports_esports;

    // Use category if available
    if (category != null) {
      switch (category.toUpperCase()) {
        case 'GAME':
          return Icons.sports_esports;
        case 'AUDIO':
        case 'MUSIC':
          return Icons.music_note;
        case 'VIDEO':
          return Icons.play_circle_fill;
        case 'IMAGE':
        case 'PHOTOS':
          return Icons.photo;
        case 'SOCIAL':
          return Icons.people;
        case 'PRODUCTIVITY':
          return Icons.work;
      }
    }

    return Icons.apps;
  }

  /// Get brand or deterministic color for an app
  Color getAppBrandColor(String packageName, {String? appName}) {
    final lowerPkg = packageName.toLowerCase();
    for (final entry in _brandColors.entries) {
      if (lowerPkg.contains(entry.key)) {
        return entry.value;
      }
    }

    if (appName != null) {
      final lowerName = appName.toLowerCase();
      for (final entry in _brandColors.entries) {
        if (lowerName.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    // Deterministic palette pick based on package hash
    final hash = packageName.hashCode.abs();
    return _palette[hash % _palette.length];
  }
}
