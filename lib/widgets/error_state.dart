

import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context)!;
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
                  ? l.sessionExpired
                  : isMissingBoth
                  ? l.profileSetupIncomplete
                  : isMissingDoctor
                  ? l.doctorDetailsMissing
                  : l.couldNotLoadProfile,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isMissingBoth
                  ? l.profileNotSavedDuringSignup
                  : isMissingDoctor
                  ? l.doctorRegistrationIncomplete
                  : isNotAuth
                  ? l.sessionExpiredMessage
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
label: Text(isNotAuth ? l.goToLogin : l.retry),
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
label: Text(l.signOutAndReregister),
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


