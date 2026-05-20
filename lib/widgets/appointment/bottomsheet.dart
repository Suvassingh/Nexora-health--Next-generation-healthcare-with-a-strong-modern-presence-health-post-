import 'package:flutter/material.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';

import 'package:healthpost_app/models/doctor_appointment.dart';

class DetailSheet extends StatelessWidget {
  final DAppt appt;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onNoShow;

  const DetailSheet({
    required this.appt,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
    this.onNoShow,
  });

  @override
  Widget build(BuildContext context)  {
  final l = AppLocalizations.of(context)!;

   return DraggableScrollableSheet(
    initialChildSize: 0.62,
    minChildSize: 0.4,
    maxChildSize: 0.92,
    builder: (_, ctrl) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: appt.statusColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: appt.statusColor.withOpacity(0.2)),
              ),
            ),
            child: Center(
              child: Text(
                appt.statusLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: appt.statusColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              children: [
                // Patient header
                Row(
                  children: [
                    PatientAvatar(
                      name: appt.patientName,
                      url: appt.patientAvatarUrl,
                      size: 58,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt.patientName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                              l.patient,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
               Rows(Icons.calendar_today_rounded, l.date, appt.dateLabel),
                  Rows(Icons.access_time_rounded, l.time, appt.timeLabel),
                  Rows(appt.consultIcon, l.type, appt.consultLabel),
                  if (appt.patientNotes?.isNotEmpty == true)
                    Rows(Icons.notes_rounded, l.reason, appt.patientNotes!),
                const SizedBox(height: 24),
                // Action buttons
                if (onConfirm != null && onDecline != null) ...[
                  ActionBtn(
label: l.confirmAppointment,
                    icon: Icons.check_rounded,
                    color: const Color(0xFF1565C0),
                    onTap: onConfirm!,
                  ),
                  const SizedBox(height: 10),
                  ActionBtn(
label: l.declineAppointment,
                    icon: Icons.close_rounded,
                    color: Colors.red,
                    outlined: true,
                    onTap: onDecline!,
                  ),
                ],
                if (onComplete != null && onNoShow != null) ...[
                  ActionBtn(
label: l.markAsCompleted,
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF2E7D32),
                    onTap: onComplete!,
                  ),
                  const SizedBox(height: 10),
                  ActionBtn(
label: l.patientNoShow,
                    icon: Icons.person_off_outlined,
                    color: Colors.brown.shade600,
                    outlined: true,
                    onTap: onNoShow!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class PatientAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;

  const PatientAvatar({required this.name, this.url, required this.size});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : 'P';
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.blueGrey.shade50,
      backgroundImage: url != null && url!.isNotEmpty
          ? NetworkImage(url!)
          : null,
      child: url == null || url!.isEmpty
          ? Text(
              _initials,
              style: TextStyle(
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

class Rows extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const Rows(this.icon, this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.35)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: color,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }
}
