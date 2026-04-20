import 'package:healthpost_app/models/doctor_appointment.dart';

class DoctorChatPreview {
  final DAppt appt;
  final String conversationId;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const DoctorChatPreview({
    required this.appt,
    required this.conversationId,
    required this.lastMessage,
    required this.lastMessageAt,
  });
}
