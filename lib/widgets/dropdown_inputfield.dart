import 'package:flutter/material.dart';

class DropdownInputField<T> extends StatelessWidget {
  const DropdownInputField({
    super.key,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.value,
    this.display,
    this.icon,
    this.label,
  });

  final String hintText;
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;

  /// Optional: convert item to display string. Defaults to item.toString()
  final String Function(T)? display;

  /// Optional: if provided, renders an icon + label above the dropdown
  final IconData? icon;
  final String? label;

  String _displayOf(T item) =>
      display != null ? display!(item) : item.toString();

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hintText,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFFCBD5E1),
          fontWeight: FontWeight.w400,
        ),
      ),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF94A3B8),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: label != null
            ? const Color(0xFFF8FAFC) // profile-style: solid fill
            : Colors.white.withValues(alpha: 0.2), // auth-style: translucent
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
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
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(_displayOf(item))),
          )
          .toList(),
      onChanged: onChanged,
    );

    // ── Simple mode (no label/icon) ──────────────────────────────────────────
    if (icon == null && label == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: dropdown,
      );
    }

    // ── Profile mode (with label/icon) ───────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null || label != null)
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Theme.of(context).primaryColor),
                const SizedBox(width: 6),
              ],
              if (label != null)
                Text(
                  label!,
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
        dropdown,
      ],
    );
  }
}
