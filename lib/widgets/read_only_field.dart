import 'package:flutter/material.dart';


class ReadOnlyField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? note;

  const ReadOnlyField({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFCBD5E1),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
      if (note != null) ...[
        const SizedBox(height: 4),
        Text(
          note!,
          style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
        ),
      ],
    ],
  );
}
