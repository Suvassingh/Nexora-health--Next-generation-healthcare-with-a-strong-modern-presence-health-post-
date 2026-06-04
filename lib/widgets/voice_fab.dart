// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:healthpost_app/app_constants.dart';
// import 'package:healthpost_app/l10n/app_localizations.dart';
// import 'package:healthpost_app/services/tts_service.dart';
//
// class VoiceFab extends StatelessWidget {
//   final String text;
//   final String language;
//   final Object? heroTag;   // <-- new parameter
//
//   const VoiceFab({
//     super.key,
//     required this.text,
//     this.language = 'en-US',
//     this.heroTag,          // pass a unique tag per screen
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final tts = TtsService();
//     final l = AppLocalizations.of(context)!;
//
//     return Obx(
//           () => FloatingActionButton(
//         heroTag: heroTag ?? runtimeType,  // use provided tag or class name
//         onPressed: () => tts.toggle(text, language: language),
//         backgroundColor: tts.isSpeaking.value
//             ? const Color(0xFFEF4444)
//             : AppConstants.primaryColor,
//         tooltip: tts.isSpeaking.value ? l.stop : l.readAloud,
//         child: AnimatedSwitcher(
//           duration: const Duration(milliseconds: 250),
//           child: Icon(
//             tts.isSpeaking.value
//                 ? Icons.stop_rounded
//                 : Icons.volume_up_rounded,
//             key: ValueKey(tts.isSpeaking.value),
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }