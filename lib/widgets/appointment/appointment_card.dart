import 'package:flutter/material.dart';
import 'package:healthpost_app/models/doctor_appointment.dart';
import 'package:healthpost_app/app_constants.dart';

class ApptCard extends StatelessWidget {
  final DAppt appt;
  final bool processing;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onNoShow;
  final VoidCallback? onConsultTap; // only for today's appointments

  const ApptCard({
    super.key,
    required this.appt,
    required this.processing,
    required this.onTap,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
    this.onNoShow,
    this.onConsultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    child: Text(
                      appt.initials,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appt.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appt.dateTimeLabel,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (appt.patientNotes != null && appt.patientNotes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              appt.patientNotes!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Consultation icon – only if onConsultTap is provided (today tab)
                  if (onConsultTap != null)
                    GestureDetector(
                      onTap: onConsultTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: appt.consultIconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          appt.consultIcon,
                          size: 22,
                          color: appt.consultIconColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: appt.statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appt.statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (onConfirm != null || onDecline != null || onComplete != null || onNoShow != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onConfirm != null)
                        ElevatedButton(
                          onPressed: processing ? null : onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Confirm'),
                        ),
                      if (onDecline != null)
                        OutlinedButton(
                          onPressed: processing ? null : onDecline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                      if (onComplete != null)
                        ElevatedButton(
                          onPressed: processing ? null : onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Complete'),
                        ),
                      if (onNoShow != null)
                        OutlinedButton(
                          onPressed: processing ? null : onNoShow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.brown,
                            side: const BorderSide(color: Colors.brown),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('No Show'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}