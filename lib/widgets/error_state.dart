

import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';

class ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;
  const ErrorState({
    required this.error,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isMissingDoctor = error.contains('no_doctor_profile');
    final isMissingBoth = error.contains('no_profile');
    final isNotAuth = error.contains('Not authenticated');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNotAuth
                    ? Icons.lock_outline_rounded
                    : isMissingBoth || isMissingDoctor
                    ? Icons.person_off_outlined
                    : Icons.cloud_off_rounded,
                size: 32,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isNotAuth
                  ? 'Session expired'
                  : isMissingBoth
                  ? 'Profile setup incomplete'
                  : isMissingDoctor
                  ? 'Doctor details missing'
                  : 'Could not load profile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isMissingBoth
                  ? 'Profile data was not saved during signup.\nSign out and register again.'
                  : isMissingDoctor
                  ? 'Doctor registration incomplete.\nContact your administrator.'
                  : isNotAuth
                  ? 'Your session has expired. Please login again.'
                  : error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isNotAuth ? onSignOut : onRetry,
                icon: Icon(
                  isNotAuth ? Icons.login_rounded : Icons.refresh_rounded,
                ),
                label: Text(isNotAuth ? 'Go to Login' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (isMissingBoth || isMissingDoctor) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 15),
                label: const Text('Sign out & re-register'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


