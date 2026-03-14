import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
class HeroHeader extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String healthpostName;
  final String? avatarUrl;
  final String initials;
  final String greeting;
  final String todayLabel;

  const HeroHeader({
    required this.doctorName,
    required this.specialty,
    required this.healthpostName,
    required this.avatarUrl,
    required this.initials,
    required this.greeting,
    required this.todayLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dr. ${doctorName.split(' ').first}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _AvatarInitials(initials: initials, size: 52),
                        ),
                      )
                    : _AvatarInitials(initials: initials, size: 52),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Info row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  size: 15,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    healthpostName.isEmpty ? 'Health Post' : healthpostName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.white30,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                const Icon(
                  Icons.medical_services_outlined,
                  size: 15,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  specialty.isEmpty ? 'General' : specialty,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Date row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Colors.white60,
              ),
              const SizedBox(width: 5),
              Text(
                todayLabel,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String initials;
  final double size;

  const _AvatarInitials({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
