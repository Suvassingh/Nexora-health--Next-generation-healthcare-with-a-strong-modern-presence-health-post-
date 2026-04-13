import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/models/doctor_appointment.dart';
import 'package:healthpost_app/app_constants.dart';

class ConsultationScreen extends StatelessWidget {
  final DAppt appt;

  const ConsultationScreen({super.key, required this.appt});

  @override
  Widget build(BuildContext context) {
    final consultType = appt.consultType;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: Text('Consultation with ${appt.patientName}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              appt.consultIcon,
              size: 64,
              color: appt.consultIconColor,
            ),
            const SizedBox(height: 24),
            Text(
              '${appt.consultLabel} consultation',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Patient: ${appt.patientName}\nTime: ${appt.dateTimeLabel}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Replace with actual call/chat logic
                Get.snackbar(
                  'Join ${appt.consultLabel}',
                  'Starting consultation...',
                  backgroundColor: AppConstants.primaryColor,
                  colorText: Colors.white,
                );
              },
              icon: Icon(appt.consultIcon),
              label: Text('Join ${appt.consultLabel} Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appt.consultIconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}