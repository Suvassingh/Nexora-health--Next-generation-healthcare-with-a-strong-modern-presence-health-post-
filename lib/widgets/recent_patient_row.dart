import 'package:flutter/material.dart';

import '../app_constants.dart';
import '../home_page.dart';
class RecentPatientsRow extends StatelessWidget {
  final List<AppointmentItem> appointments;
  const RecentPatientsRow({super.key, required this.appointments});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final a = appointments[i];
          return Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
                child: Text(a.patientInitials ?? '?',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const SizedBox(height: 4),
              Text(a.patientName.split(' ').first,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF374151))),
            ],
          );
        },
      ),
    );
  }
}