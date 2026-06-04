import 'package:flutter/material.dart';

class DAppt {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientAvatarUrl;
  final DateTime scheduledAt;
  final String status;
  final String consultType;
  final String? patientNotes;

  const DAppt({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientAvatarUrl,
    required this.scheduledAt,
    required this.status,
    required this.consultType,
    this.patientNotes,
  });

  String get initials {
    final pts = patientName.trim().split(' ');
    if (pts.length >= 2) return '${pts[0][0]}${pts[1][0]}'.toUpperCase();
    return pts.isNotEmpty && pts[0].isNotEmpty ? pts[0][0].toUpperCase() : 'P';
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'no_show';
  bool get isUpcoming =>
      (isPending || isConfirmed) && scheduledAt.isAfter(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  bool get isTomorrow {
    final tom = DateTime.now().add(const Duration(days: 1));
    return scheduledAt.year == tom.year &&
        scheduledAt.month == tom.month &&
        scheduledAt.day == tom.day;
  }

  String get dateLabel {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${scheduledAt.day} ${m[scheduledAt.month - 1]}';
  }

  String get timeLabel {
    final h = scheduledAt.hour % 12 == 0 ? 12 : scheduledAt.hour % 12;
    final mm = scheduledAt.minute.toString().padLeft(2, '0');
    final ap = scheduledAt.hour < 12 ? 'AM' : 'PM';
    return '$h:$mm $ap';
  }

  String get dateTimeLabel => '$dateLabel, $timeLabel';

  IconData get consultIcon => switch (consultType) {
    'video' => Icons.videocam_rounded,
    'audio' => Icons.phone_rounded,
    _ => Icons.chat_bubble_rounded,
  };

  Color get consultIconColor => switch (consultType) {
    'video' => const Color(0xFF6C5CE7),
    'audio' => const Color(0xFF00B894),
    _ => const Color(0xFF0984E3),
  };

  String get consultLabel => switch (consultType) {
    'video' => 'Video',
    'audio' => 'Audio',
    _ => 'Chat',
  };

  Color get statusColor => switch (status) {
    'pending' => const Color(0xFFE65100),
    'confirmed' => const Color(0xFF1565C0),
    'completed' => const Color(0xFF2E7D32),
    'cancelled' => const Color(0xFF757575),
    'no_show' => const Color(0xFF6D4C41),
    _ => const Color(0xFF546E7A),
  };

  String get statusLabel => switch (status) {
    'pending' => 'Pending',
    'confirmed' => 'Confirmed',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    'no_show' => 'No Show',
    _ => status,
  };

  factory DAppt.fromApi(Map<String, dynamic> json) {
    final profile = json['user_profiles'] as Map<String, dynamic>? ?? {};

    print(
      ' patient_id raw: ${json['patient_id']} (${json['patient_id'].runtimeType})',
    );
    print('Appointment JSON: $json');
    return DAppt(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: profile['full_name']?.toString() ?? 'Patient',
      patientAvatarUrl: profile['avatar_url']?.toString(),
      scheduledAt: DateTime.parse(json['scheduled_at']).toLocal(),
      status: json['status']?.toString() ?? 'pending',
      consultType: json['consultation_type']?.toString() ?? 'audio',
      patientNotes: json['patient_notes']?.toString(),
    );
  }
}