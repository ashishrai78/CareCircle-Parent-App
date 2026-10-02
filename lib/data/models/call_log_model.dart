import 'package:cloud_firestore/cloud_firestore.dart';

/// 📞 CallLogModel — represents a single call log entry
class CallLogModel {
  final String id;
  final CallType type;
  final String phoneNumber;
  final String? contactName;
  final int duration;
  final DateTime timestamp;
  final String? detectedBy;
  final String? source;

  CallLogModel({
    required this.id,
    required this.type,
    required this.phoneNumber,
    this.contactName,
    required this.duration,
    required this.timestamp,
    this.detectedBy,
    this.source,
  });

  factory CallLogModel.fromMap(String docId, Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? 'unknown';
    return CallLogModel(
      id: docId,
      type: CallType.fromString(typeStr),
      phoneNumber: data['phoneNumber'] as String? ?? 'Unknown',
      contactName: data['contactName'] as String?,
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(
            (data['deviceTime'] as num?)?.toInt() ?? 0,
          ),
      detectedBy: data['detectedBy'] as String?,
      source: data['source'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'phoneNumber': phoneNumber,
      'contactName': contactName,
      'duration': duration,
      'timestamp': Timestamp.fromDate(timestamp),
      'detectedBy': detectedBy,
      'source': source,
    };
  }

  String get typeIcon {
    switch (type) {
      case CallType.incoming: return '📞';
      case CallType.outgoing: return '📱';
      case CallType.missed: return '❌';
      case CallType.rejected: return '🚫';
      case CallType.blocked: return '⛔';
      case CallType.unknown: return '❓';
    }
  }

  int get typeColor {
    switch (type) {
      case CallType.incoming: return 0xFF4CAF50;
      case CallType.outgoing: return 0xFF2196F3;
      case CallType.missed: return 0xFFF44336;
      case CallType.rejected: return 0xFFFF9800;
      case CallType.blocked: return 0xFF9C27B0;
      case CallType.unknown: return 0xFF9E9E9E;
    }
  }

  String get typeLabel {
    switch (type) {
      case CallType.incoming: return 'Incoming';
      case CallType.outgoing: return 'Outgoing';
      case CallType.missed: return 'Missed';
      case CallType.rejected: return 'Rejected';
      case CallType.blocked: return 'Blocked';
      case CallType.unknown: return 'Unknown';
    }
  }

  String get durationFormatted {
    if (duration == 0) return '—';
    final min = duration ~/ 60;
    final sec = duration % 60;
    if (min == 0) return '$sec sec';
    if (sec == 0) return '$min min';
    return '$min min $sec sec';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String get timeOfDay {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get displayName {
    if (contactName != null && contactName!.isNotEmpty) {
      return contactName!;
    }
    return phoneNumber;
  }
}

enum CallType {
  incoming, outgoing, missed, rejected, blocked, unknown;

  static CallType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'incoming': return CallType.incoming;
      case 'outgoing': return CallType.outgoing;
      case 'missed': return CallType.missed;
      case 'rejected': return CallType.rejected;
      case 'blocked': return CallType.blocked;
      default: return CallType.unknown;
    }
  }

  String get value => toString().split('.').last;
}

class CallLogStats {
  final int totalCalls;
  final int incomingCount;
  final int outgoingCount;
  final int missedCount;
  final int totalDurationSeconds;

  CallLogStats({
    required this.totalCalls,
    this.incomingCount = 0,
    this.outgoingCount = 0,
    this.missedCount = 0,
    this.totalDurationSeconds = 0,
  });

  String get totalDurationFormatted {
    if (totalDurationSeconds == 0) return '0 min';
    final hours = totalDurationSeconds ~/ 3600;
    final min = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${min}m';
    return '$min min';
  }
}
