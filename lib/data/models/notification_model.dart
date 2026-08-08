import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔔 NotificationModel — represents one captured notification from child device
class NotificationModel {
  final String id;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final String? subText;
  final String? infoText;
  final String category;
  final String priority;
  final int postedAt; // device time (ms)
  final DateTime? timestamp; // server time
  final String dateKey; // "dd-MM-yyyy"
  final bool cleared;

  NotificationModel({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    this.subText,
    this.infoText,
    required this.category,
    required this.priority,
    required this.postedAt,
    this.timestamp,
    required this.dateKey,
    this.cleared = false,
  });

  factory NotificationModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return NotificationModel(
      id: id,
      packageName: data['packageName'] as String? ?? 'unknown',
      appName: data['appName'] as String? ?? 'Unknown',
      title: data['title'] as String? ?? '',
      text: data['text'] as String? ?? '',
      subText: data['subText'] as String?,
      infoText: data['infoText'] as String?,
      category: data['category'] as String? ?? 'unknown',
      priority: data['priority'] as String? ?? 'default',
      postedAt: (data['postedAt'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      dateKey: data['dateKey'] as String? ?? '',
      cleared: data['cleared'] as bool? ?? false,
    );
  }

  // ============ Computed Properties ============

  /// Formatted time ago (e.g., "2 min ago")
  String get timeAgo {
    final refTime = timestamp ?? DateTime.fromMillisecondsSinceEpoch(postedAt);
    final diff = DateTime.now().difference(refTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    return '${refTime.day}/${refTime.month}/${refTime.year}';
  }

  /// Time of day (e.g., "14:30")
  String get timeOfDay {
    final refTime = timestamp ?? DateTime.fromMillisecondsSinceEpoch(postedAt);
    final hour = refTime.hour.toString().padLeft(2, '0');
    final minute = refTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Full date + time (e.g., "14 Jul 2026, 14:30")
  String get dateTimeFormatted {
    final refTime = timestamp ?? DateTime.fromMillisecondsSinceEpoch(postedAt);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = refTime.hour.toString().padLeft(2, '0');
    final minute = refTime.minute.toString().padLeft(2, '0');
    return '${refTime.day} ${months[refTime.month - 1]} ${refTime.year}, $hour:$minute';
  }

  /// Whether this is a high priority notification
  bool get isHighPriority => priority == 'high' || priority == 'max';

  /// Display text — falls back to subText if main text is empty
  String get displayText {
    if (text.isNotEmpty) return text;
    if (subText != null && subText!.isNotEmpty) return subText!;
    if (infoText != null && infoText!.isNotEmpty) return infoText!;
    return '';
  }

  /// Whether notification has meaningful content
  bool get hasContent => title.isNotEmpty || displayText.isNotEmpty;

  /// Category icon (for UI)
  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'msg':
      case 'message':
        return '💬';
      case 'social':
        return '👥';
      case 'call':
        return '📞';
      case 'email':
        return '📧';
      case 'event':
        return '📅';
      case 'alarm':
        return '⏰';
      case 'news':
        return '📰';
      case 'promo':
      case 'recommendation':
        return '🎁';
      case 'error':
        return '⚠️';
      case 'progress':
        return '⏳';
      default:
        return '🔔';
    }
  }

  /// App icon emoji (best guess by package name)
  String get appEmoji {
    final pkg = packageName.toLowerCase();
    if (pkg.contains('whatsapp')) return '💬';
    if (pkg.contains('instagram')) return '📷';
    if (pkg.contains('facebook')) return '👥';
    if (pkg.contains('youtube')) return '▶️';
    if (pkg.contains('spotify')) return '🎵';
    if (pkg.contains('gmail') || pkg.contains('.gm')) return '📧';
    if (pkg.contains('chrome')) return '🌐';
    if (pkg.contains('maps')) return '🗺️';
    if (pkg.contains('snapchat')) return '👻';
    if (pkg.contains('telegram')) return '✈️';
    if (pkg.contains('tiktok')) return '🎬';
    if (pkg.contains('twitter') || pkg.contains('x.android')) return '🐦';
    if (pkg.contains('linkedin')) return '💼';
    if (pkg.contains('messages') || pkg.contains('messaging')) return '📩';
    if (pkg.contains('phone') || pkg.contains('dialer')) return '📞';
    if (pkg.contains('netflix')) return '🎬';
    if (pkg.contains('amazon')) return '📦';
    if (pkg.contains('flipkart')) return '🛒';
    if (pkg.contains('phonepe') || pkg.contains('paytm')) return '💰';
    if (pkg.contains('zomato') || pkg.contains('swiggy')) return '🍔';
    if (pkg.contains('uber') || pkg.contains('ola')) return '🚗';
    return '📱';
  }
}
