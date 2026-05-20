
import 'package:flutter/material.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/models/doctor_chat_preview.dart';

class DoctorChatTile extends StatelessWidget {
  final DoctorChatPreview preview;
  final String currentUserId;
  final VoidCallback onTap;

  const DoctorChatTile({
    required this.preview,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appt = preview.appt;
final l = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFF0D47A1).withOpacity(0.12),
          backgroundImage: appt.patientAvatarUrl != null
              ? NetworkImage(appt.patientAvatarUrl!)
              : null,
          child: appt.patientAvatarUrl == null
              ? Text(
                  appt.initials,
                  style: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        title: Text(
          appt.patientName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
preview.lastMessage ?? l.noMessagesYet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: preview.lastMessage != null
                  ? Colors.grey.shade700
                  : Colors.grey.shade400,
            ),
          ),
        ),
        trailing: preview.lastMessageAt != null
            ? Text(
                _formatTime(preview.lastMessageAt!, l),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              )
            : null,
      ),
    );
  }

  String _formatTime(DateTime dt, AppLocalizations l) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inHours < 1) return l.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return l.daysAgo(diff.inDays);
    return '${dt.day}/${dt.month}';
  }
}
