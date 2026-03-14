import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';


class LangTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const LangTab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppConstants.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : const Color(0xFF94A3B8),
        ),
      ),
    ),
  );
}
