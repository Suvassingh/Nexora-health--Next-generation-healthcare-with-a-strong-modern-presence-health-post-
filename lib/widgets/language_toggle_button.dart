import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/controller/locale_conreoller.dart';
import 'package:healthpost_app/main.dart';


// class LanguageToggleButton extends StatelessWidget {
//   const LanguageToggleButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final currentLang = HealthpostApp.of(context)?.currentLanguageCode;

//     return Container(
//       padding: const EdgeInsets.all(2),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.2),
//         borderRadius: BorderRadius.circular(25),
//       ),
//       child: ToggleButtons(
//         borderRadius: BorderRadius.circular(25),
//         borderWidth: 0,
//         constraints: const BoxConstraints(minHeight: 30, minWidth: 30),
//         selectedColor: AppConstants.primaryColor,
//         fillColor: Colors.white,
//         color: Colors.white,
//         isSelected: [currentLang == 'en', currentLang == 'ne'],
//         onPressed: (index) {
//           if (index == 0) {
//             HealthpostApp.of(context)?.changeLanguage('en');
//           } else {
//             HealthpostApp.of(context)?.changeLanguage('ne');
//           }
//         },
//         children: const [
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 8),
//             child: Text(
//               'En',
//               style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Text(
//               "ने",
//               style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = HealthpostApp.of(context)?.currentLanguageCode;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // English
          _langButton(
            context,
            label: "EN",
            selected: currentLang == 'en',
            onTap: () {
              HealthpostApp.of(context)?.changeLanguage('en');
              Get.find<LocaleController>().setLocale('en'); 
            },
            
          ),

          // Nepali
          _langButton(
            context,
            label: "ने",
            selected: currentLang == 'ne',
            onTap: () {
              HealthpostApp.of(context)?.changeLanguage('ne');
              Get.find<LocaleController>().setLocale('np'); 
            },
          ),
        ],
      ),
    );
  }

  Widget _langButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppConstants.primaryColor : Colors.white,
          ),
        ),
      ),
    );
  }
}

