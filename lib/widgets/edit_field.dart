import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart';
class EditField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType inputType;
  final TextCapitalization capitalization;
  final int maxLines;

  const EditField({
    required this.icon,
    required this.label,
    required this.controller,
    this.hint,
    this.inputType = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: AppConstants.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: inputType,
        textCapitalization: capitalization,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppConstants.primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    ],
  );
}
