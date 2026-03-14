import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/home_page.dart';

class StatsGrid extends StatelessWidget {
  final HomeStats stats;
  const StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(
                label: "Today's patients",
                value: stats.todayPatients.toString(),
                icon: Icons.groups_outlined,
                color: AppConstants.primaryColor,
                bgColor: const Color(0xFFE8F4FD),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Pending',
                value: stats.pending.toString(),
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFFF39C12),
                bgColor: const Color(0xFFFFF8E8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                label: 'Completed',
                value: stats.completed.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF27AE60),
                bgColor: const Color(0xFFEAF7EF),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'This month',
                value: stats.totalThisMonth.toString(),
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF8E44AD),
                bgColor: const Color(0xFFF5EEF8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
