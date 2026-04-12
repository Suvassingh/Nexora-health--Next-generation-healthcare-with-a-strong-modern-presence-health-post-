import 'package:flutter/material.dart';


class DAppt {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientAvatarUrl;
  final DateTime scheduledAt;
  final String status;
  final String consultType;
  final String? patient_notes;

  const DAppt({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientAvatarUrl,
    required this.scheduledAt,
    required this.status,
    required this.consultType,
    this.patient_notes,
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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

  factory DAppt.fromMap(Map<String, dynamic> m) {
    // patient_id FK → user_profiles.id
    final prof =
        m['user_profiles!appointments_patient_id_fkey']
            as Map<String, dynamic>? ??
        m['user_profiles'] as Map<String, dynamic>? ??
        {};
    return DAppt(
      id: m['id']?.toString() ?? '',
      patientId: m['patient_id']?.toString() ?? '',
      patientName: prof['full_name']?.toString() ?? 'Patient',
      patientAvatarUrl: prof['avatar_url']?.toString(),
      scheduledAt: DateTime.parse(m['scheduled_at']).toLocal(),
      status: m['status']?.toString() ?? 'pending',
      consultType: m['consultation_type']?.toString() ?? 'audio',
      patient_notes: m['patient_notes']?.toString(),
    );
  }
}
