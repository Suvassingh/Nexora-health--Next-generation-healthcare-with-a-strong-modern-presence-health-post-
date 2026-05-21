import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/controller/locale_conreoller.dart';
import 'package:healthpost_app/doctor_patient_list_screen.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/widgets/language_toggle_button.dart';
import 'package:healthpost_app/widgets/stile.dart';

class SettingsCard extends StatelessWidget {
  final LocaleController localeCtrl;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLogout;

  const SettingsCard({
    super.key,
    required this.localeCtrl,
    required this.onLanguageChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Settings Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 16,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l.settings,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),

          /// Settings Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                /// Language Selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      /// Icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EEF8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: Color(0xFF8E44AD),
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.language,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              l.appDisplayLanguage,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const LanguageToggleButton()),
                    ],
                  ),
                ),

                _div(),

                /// Change Password
                STile(
                  icon: Icons.lock_outline_rounded,
                  iconBg: const Color(0xFFEBF5FD),
                  iconColor: AppConstants.primaryColor,
                  label: l.changePassword,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFCBD5E1),
                  ),
                  onTap: () => Get.snackbar(
                    l.comingSoon,
                    l.passwordChangeSoon,
                    backgroundColor: Colors.white,
                    colorText: const Color(0xFF1A1A2E),
                    borderRadius: 14,
                    margin: const EdgeInsets.all(12),
                  ),
                ),

                _div(),

                /// About App
                STile(
                  icon: Icons.info_outline_rounded,
                  iconBg: const Color(0xFFEAF7EF),
                  iconColor: const Color(0xFF27AE60),
                  label: l.aboutApp,
                  sub: l.appVersion,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFCBD5E1),
                  ),
                  onTap: () => Get.to(() => DoctorPatientListScreen()),
                ),

                _div(),

                /// Logout
                STile(
                  icon: Icons.logout_rounded,
                  iconBg: const Color(0xFFFEF2F2),
                  iconColor: const Color(0xFFEF4444),
                  label: l.logout,
                  labelColor: const Color(0xFFEF4444),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _div() => Container(
    height: 1,
    margin: const EdgeInsets.only(left: 70),
    color: const Color(0xFFF1F5F9),
  );
}
