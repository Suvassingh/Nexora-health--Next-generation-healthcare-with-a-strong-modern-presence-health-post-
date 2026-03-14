import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/models/doctor_model.dart';


class StatsStrip extends StatelessWidget {
  final DoctorProfileModel doctor;
  const StatsStrip({required this.doctor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatTile(
              value: doctor.experienceYears != null
                  ? '${doctor.experienceYears} yrs'
                  : '—',
              label: 'Experience',
              icon: Icons.timer_outlined,
              color: AppConstants.primaryColor,
              bg: const Color(0xFFEBF5FD),
            ),
            _vLine(),
            _StatTile(
              value: doctor.isActive ? 'Active' : 'Inactive',
              label: 'Status',
              icon: doctor.isActive
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: doctor.isActive ? const Color(0xFF27AE60) : Colors.grey,
              bg: doctor.isActive
                  ? const Color(0xFFEAF7EF)
                  : const Color(0xFFF3F4F6),
            ),
            _vLine(),
            _StatTile(
              value: doctor.preferredLanguage == 'nepali'
                  ? 'नेपाली'
                  : 'English',
              label: 'Language',
              icon: Icons.language_rounded,
              color: const Color(0xFF8E44AD),
              bg: const Color(0xFFF5EEF8),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _vLine() => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(vertical: 16),
    color: const Color(0xFFF1F5F9),
  );
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color, bg;
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    ),
  );
}
