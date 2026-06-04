
import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/models/doctor_chat_preview.dart';

class DoctorChatTile extends StatelessWidget {
  final DoctorChatPreview preview;
  final String currentUserId;
  final VoidCallback onTap;

  const DoctorChatTile({
    super.key,
    required this.preview,
    required this.currentUserId,
    required this.onTap,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 24) return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: preview.patientAvatarUrl != null
                ? NetworkImage(preview.patientAvatarUrl!)
                : null,
            child: preview.patientAvatarUrl == null
                ? Text(preview.patientName[0].toUpperCase())
                : null,
          ),
          if (preview.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              preview.patientName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (!preview.hasTodayAppointment)
            Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
        ],
      ),
      subtitle: preview.lastMessage != null
          ? Text(preview.lastMessage!,
          maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatTime(preview.lastMessageAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (preview.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                preview.unreadCount.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}