import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/controller/locale_conreoller.dart';
import 'package:healthpost_app/widgets/language_tab.dart';
import 'package:healthpost_app/widgets/stile.dart';


class SettingsCard extends StatelessWidget {
  final LocaleController localeCtrl;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLogout;

  const SettingsCard({
    required this.localeCtrl,
    required this.onLanguageChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
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
              // Language toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EEF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        size: 20,
                        color: Color(0xFF8E44AD),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Language',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'App display language',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(() {
                      final isNp = localeCtrl.isNepali;
                      return Container(
                        height: 36,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LangTab(
                              label: 'EN',
                              active: !isNp,
                              onTap: () => onLanguageChanged('en'),
                            ),
                            LangTab(
                              label: 'नेपाली',
                              active: isNp,
                              onTap: () => onLanguageChanged('np'),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              _div(),
              // Change password
              STile(
                icon: Icons.lock_outline_rounded,
                iconBg: const Color(0xFFEBF5FD),
                iconColor: AppConstants.primaryColor,
                label: 'Change Password',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFCBD5E1),
                ),
                onTap: () => Get.snackbar(
                  'Coming Soon',
                  'Password change will be available soon.',
                  backgroundColor: Colors.white,
                  colorText: const Color(0xFF1A1A2E),
                  borderRadius: 14,
                  margin: const EdgeInsets.all(12),
                ),
              ),
              _div(),

              // About
              STile(
                icon: Icons.info_outline_rounded,
                iconBg: const Color(0xFFEAF7EF),
                iconColor: const Color(0xFF27AE60),
                label: 'About App',
                sub: 'Version 1.0.0',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFCBD5E1),
                ),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'HealthPost Doctor',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Image(
                    image: AssetImage('assets/images/gov_logo.webp'),
                    width: 44,
                    height: 44,
                  ),
                  children: const [
                    Text(
                      'A digital health management system for '
                      "Nepal's government health posts.",
                    ),
                  ],
                ),
              ),
              _div(),

              // Logout
              STile(
                icon: Icons.logout_rounded,
                iconBg: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFEF4444),
                label: 'Logout',
                labelColor: const Color(0xFFEF4444),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _div() => Container(
    height: 1,
    margin: const EdgeInsets.only(left: 70),
    color: const Color(0xFFF1F5F9),
  );
}
