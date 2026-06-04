
class DoctorChatPreview {
  final String conversationId;
  final String patientId;
  final String patientName;
  final String? patientAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool hasTodayAppointment;
final bool
  canMessageNow; 

  const DoctorChatPreview({
    required this.conversationId,
    required this.patientId,
    required this.patientName,
    this.patientAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
    this.hasTodayAppointment = false,
    this.canMessageNow = false,
  });
}