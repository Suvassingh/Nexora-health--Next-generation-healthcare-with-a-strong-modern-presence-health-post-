import 'package:flutter/material.dart';
import 'package:healthpost_app/app_constants.dart'; 
class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.keyboardType,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      style: const TextStyle(
        color: Colors.black87,
      ), 
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
