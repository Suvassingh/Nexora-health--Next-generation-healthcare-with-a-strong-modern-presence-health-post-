import 'package:flutter/material.dart';
import 'package:healthpost_app/appointment_screen.dart';
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
  Widget build(BuildContext context) => DraggableScrollableSheet(
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
                            'Patient',
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
                Rows(Icons.calendar_today_rounded, 'Date', appt.dateLabel),
                Rows(Icons.access_time_rounded, 'Time', appt.timeLabel),
                Rows(appt.consultIcon, 'Type', appt.consultLabel),
                if (appt.patient_notes?.isNotEmpty == true)
                  Rows(Icons.notes_rounded, 'Reason', appt.patient_notes!),
                const SizedBox(height: 24),
                // Action buttons
                if (onConfirm != null && onDecline != null) ...[
                  ActionBtn(
                    label: 'Confirm Appointment',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF1565C0),
                    onTap: onConfirm!,
                  ),
                  const SizedBox(height: 10),
                  ActionBtn(
                    label: 'Decline Appointment',
                    icon: Icons.close_rounded,
                    color: Colors.red,
                    outlined: true,
                    onTap: onDecline!,
                  ),
                ],
                if (onComplete != null && onNoShow != null) ...[
                  ActionBtn(
                    label: 'Mark as Completed',
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF2E7D32),
                    onTap: onComplete!,
                  ),
                  const SizedBox(height: 10),
                  ActionBtn(
                    label: 'Patient No-Show',
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
