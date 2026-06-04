
class AppNotification {
  final String id;
  final String userId;
  final String userType;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.userType,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        userType: json['user_type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    userId: userId,
    userType: userType,
    title: title,
    body: body,
    type: type,
    data: data,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  static const Map<String, String> _typeIcons = {
    'appointment_confirmed': '✅',
    'appointment_cancelled': '❌',
    'appointment_reminder': '⏰',
    'new_appointment': '📋',
    'call_incoming': '📞',
    'chat_message': '💬',
    'no_show': '🚫',
    'completed': '🎉',
  };

  String get icon => _typeIcons[type] ?? '🔔';
}
