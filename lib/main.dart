import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/services/notification_service.dart';
import 'package:healthpost_app/services/tts_service.dart';
import 'package:healthpost_app/splash_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/controller/internet_status_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['supabase_url']!,
    anonKey: dotenv.env['supabase_anonKey']!,
  );
  await NotificationService.instance.initialize();

  Get.put(ConnectivityController(), permanent: true);
  await TtsService().init();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String languageCode = prefs.getString("language") ?? "en";

  runApp(ProviderScope(child: HealthpostApp(languageCode: languageCode)));
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
