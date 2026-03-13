import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/home_screen.dart';
import 'package:healthpost_app/login_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _percentage = 0;
  late final Timer _timer;
  final supabase = Supabase.instance.client;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_percentage < 100) {
        setState(() {
          _percentage += 1;
        });
        // ❌ REMOVED: navigation from inside the increment block
      } else {
        timer.cancel();
        // Get.offAll(() => const HomeScreen());

        // ✅ Navigate once here, with correct auth check
        if (supabase.auth.currentSession == null) {
          Get.offAll(() => LoginScreen());
        } else {
          Get.offAll(() => HomeScreen());
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/gov_logo.webp", width: 150, height: 150),
            const SizedBox(height: 20),
            Text(
              AppConstants.nepalSarkar,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              AppConstants.govtOfNepal,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Text(
              AppConstants.swasthyaposttelemedicine,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              AppConstants.telemedicine,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 90),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 170),
              child: LinearProgressIndicator(value: _percentage / 100),
            ),
            const SizedBox(height: 10),

            Text(
              'Loading... $_percentage%',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
