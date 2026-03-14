import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/models/doctor_model.dart';
import 'package:healthpost_app/verified_batch.dart';
import 'package:healthpost_app/widgets/contact_btn.dart';
import 'package:healthpost_app/widgets/information_under_pp.dart';
import 'package:healthpost_app/widgets/profile_pic.dart';
class HeroBanner extends StatelessWidget {
  final DoctorProfileModel doctor;
  final String initials;
  const HeroBanner({required this.doctor, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Blue banner
        Container(
          width: double.infinity,
          height: 100,
          color: AppConstants.primaryColor,
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Circle(130, Colors.white.withOpacity(0.06)),
              ),
              Positioned(
                top: 20,
                left: -20,
                child: Circle(80, Colors.white.withOpacity(0.05)),
              ),
              Positioned(
                top: 14,
                right: 18,
                child: VerifBadge(verified: doctor.doctorIsVerified),
              ),
            ],
          ),
        ),

        // White card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Column(
              children: [
                Text(
                  'Dr. ${doctor.fullName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    InfoChip(
                      icon: Icons.medical_services_outlined,
                      label: doctor.specialty.isEmpty
                          ? 'Doctor'
                          : doctor.specialty,
                      bg: const Color(0xFFEBF5FD),
                      fg: AppConstants.primaryColor,
                    ),
                    InfoChip(
                      icon: Icons.location_on_outlined,
                      label: doctor.healthpostName.isEmpty
                          ? 'Health Post'
                          : doctor.healthpostName,
                      bg: const Color(0xFFEAF7EF),
                      fg: const Color(0xFF1A7A4A),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (doctor.licenseNumber.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'NMC # ${doctor.licenseNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ContactBtn(
                      icon: Icons.phone_outlined,
                      label: doctor.phone.isEmpty ? '—' : doctor.phone,
                      color: AppConstants.primaryColor,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: const Color(0xFFF1F5F9),
                    ),
                    ContactBtn(
                      icon: Icons.email_outlined,
                      label: doctor.email.isEmpty ? '—' : doctor.email,
                      color: const Color(0xFF8E44AD),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Avatar
        Positioned(
          top: 72 - 44,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child:
                      doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty
                      ? Image.network(
                          doctor.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              AvatarFill(initials: initials),
                        )
                      : AvatarFill(initials: initials),
                ),
              ),
            ),
          ),
        ),

        // Online dot
        Positioned(
          top: 72 - 44 + 64,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.translate(
              offset: const Offset(30, 0),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: doctor.isActive
                      ? const Color(0xFF2ECC71)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
