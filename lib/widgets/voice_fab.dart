import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/services/tts_service.dart';

class VoiceFab extends StatelessWidget {
  final String text;
  final String language;

  const VoiceFab({
    super.key,
    required this.text,
    this.language = 'en-US',
  });

  @override
  Widget build(BuildContext context) {
    final tts = TtsService(); // ← factory returns same singleton instance
    return Obx(
          () => FloatingActionButton(
        onPressed: () => tts.toggle(text, language: language),
        backgroundColor: tts.isSpeaking.value
            ? const Color(0xFFEF4444)
            : AppConstants.primaryColor,
        tooltip: tts.isSpeaking.value ? 'Stop' : 'Read aloud',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Icon(
            tts.isSpeaking.value
                ? Icons.stop_rounded
                : Icons.volume_up_rounded,
            key: ValueKey(tts.isSpeaking.value),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}