import 'package:flutter/material.dart';


class VerifBadge extends StatelessWidget {
  final bool verified;
  const VerifBadge({required this.verified});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: verified
          ? const Color(0xFF2ECC71).withOpacity(0.14)
          : const Color(0xFFF39C12).withOpacity(0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: verified
            ? const Color(0xFF2ECC71).withOpacity(0.45)
            : const Color(0xFFF39C12).withOpacity(0.45),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified ? Icons.verified_rounded : Icons.hourglass_empty_rounded,
          size: 12,
          color: verified ? const Color(0xFF2ECC71) : const Color(0xFFF39C12),
        ),
        const SizedBox(width: 5),
        Text(
          verified ? 'NMC Verified' : 'Pending',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: verified ? const Color(0xFF1A8A4A) : const Color(0xFFA06000),
          ),
        ),
      ],
    ),
  );
}
