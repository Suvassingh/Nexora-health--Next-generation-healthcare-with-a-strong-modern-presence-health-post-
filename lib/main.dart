import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/splash_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/controller/internet_status_controller.dart';

void main() async {
  Get.put(ConnectivityController(), permanent: true);
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String languageCode = prefs.getString("language") ?? "en";
  await Supabase.initialize(
    url: dotenv.env['supabase_url']!,
    anonKey: dotenv.env['supabase_anonKey']!,
  );
  runApp(HealthpostApp(languageCode: languageCode));
}

class HealthpostApp extends StatefulWidget {
  final String languageCode;

  const HealthpostApp({super.key, required this.languageCode});

  static HealthpostAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<HealthpostAppState>();

  @override
  State<HealthpostApp> createState() => HealthpostAppState();
}

class HealthpostAppState extends State<HealthpostApp> {
  String get currentLanguageCode => _locale.languageCode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.languageCode);
  }

  void changeLanguage(String code) async {
    Locale newLocale = Locale(code);
    setState(() {
      _locale = Locale(code);
    });
    Get.updateLocale(newLocale);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", code);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('ne')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
