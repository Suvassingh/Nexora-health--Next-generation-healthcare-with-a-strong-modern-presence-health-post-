import 'package:flutter/material.dart';
class NoticeStrip extends StatelessWidget {
  final List<String> notices;
  const NoticeStrip({super.key, required this.notices});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF39C12).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined,
                color: Color(0xFFF39C12), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: notices.isEmpty
                  ? const Text('No notices today',
                  style: TextStyle(fontSize: 12, color: Colors.grey))
                  : Text(notices.first,
                style: const TextStyle(fontSize: 12, color: Color(0xFFA06000)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (notices.length > 1)
              Text('+${notices.length - 1} more',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFF39C12),
                    fontWeight: FontWeight.w600,
                  )),
          ],
        ),
      ),
    );
  }
}