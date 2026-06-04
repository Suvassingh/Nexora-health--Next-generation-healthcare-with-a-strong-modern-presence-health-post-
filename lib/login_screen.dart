
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/controller/internet_status_controller.dart';
import 'package:healthpost_app/home_screen.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/signup_screen.dart';
import 'package:healthpost_app/widgets/connectivity_icon.dart';
import 'package:healthpost_app/widgets/image_button.dart';
import 'package:healthpost_app/widgets/input_field.dart';
import 'package:healthpost_app/widgets/language_toggle_button.dart';
import 'package:healthpost_app/widgets/login_signup_button.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/fcm_service.dart';

class LoginController extends GetxController {
  final supabase = Supabase.instance.client;
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final isLoading = false.obs;
  bool _isLoggingIn = false;

  Future<void> login(BuildContext context) async {
    if (_isLoggingIn) return;
    _isLoggingIn = true;
    final l = AppLocalizations.of(context)!;
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (email.isEmpty) {
      Get.snackbar(l.error, l.emailRequired);
      _isLoggingIn = false;
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      Get.snackbar(l.error, l.invalidEmail);
      _isLoggingIn = false;
      return;
    }
    if (password.isEmpty) {
      Get.snackbar(l.error, l.passwordRequired);
      _isLoggingIn = false;
      return;
    }

    // Check connectivity before network call
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      Get.snackbar(l.error, l.noInternetConnection);
      _isLoggingIn = false;
      return;
    }

    isLoading.value = true;
    try {
      final result = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) {
        Get.snackbar(l.error, l.signInFailed);
        return;
      }
      if (user.emailConfirmedAt == null) {
        await supabase.auth.signOut();
        Get.snackbar(
          l.emailNotVerifiedTitle,
          l.emailNotVerifiedMessage,
          backgroundColor: Colors.orange,
        );
        return;
      }
      // Move FCM after verification
      await FcmService.onUserLogin();
      Get.offAll(() => HomeScreen());
    } on AuthException catch (e) {
      Get.snackbar(l.error, _mapAuthError(e.message, l));
    } catch (e) {
      Get.snackbar(l.error, l.somethingWentWrong);
    } finally {
      isLoading.value = false;
      _isLoggingIn = false;
    }
  }

  Future<void> resetPassword(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    // Show a dialog to ask for email separately (prevents using login field)
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetPassword),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(hintText: l.email),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                Get.snackbar(l.error, l.enterEmailForReset);
                return;
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                Get.snackbar(l.error, l.invalidEmail);
                return;
              }
              Navigator.pop(ctx);
              try {
                await supabase.auth.resetPasswordForEmail(email);
                Get.snackbar(l.success, l.passwordResetSent);
              } catch (e) {
                Get.snackbar(l.error, l.somethingWentWrong);
              }
            },
            child: Text(l.send),
          ),
        ],
      ),
    );
    emailController.dispose();
  }
  Future<void> continueWithGoogle(BuildContext context) async {
    if (_isLoggingIn) return;
    _isLoggingIn = true;
    final l = AppLocalizations.of(context)!;
    isLoading.value = true;
    try {
      final signIn = GoogleSignIn.instance;
      await signIn.initialize(
        serverClientId: dotenv.env['web_clientid'],
        clientId: Platform.isAndroid
            ? dotenv.env['android_clientid']
            : dotenv.env['ios_clientid'],
      );
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken ?? '';
      final result = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      if (result.user == null) return;

      // Check doctor profile completeness
      final doctor = await supabase
          .from('doctors')
          .select()
          .eq('user_id', result.user!.id)
          .maybeSingle();
      if (doctor == null) {
        Get.snackbar(
          l.incompleteProfile,
          l.completeDoctorProfileHint,
          backgroundColor: Colors.orange,
        );
      } else {
        final hasComplete = doctor['specialty'] != null &&
            doctor['license_number'] != null &&
            doctor['healthpost_id'] != null;
        if (!hasComplete) {
          Get.snackbar(
            l.incompleteProfile,
            l.completeDoctorProfileHint,
            backgroundColor: Colors.orange,
          );
        }
      }

      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar(l.googleSignInFailed, l.somethingWentWrong);
    } finally {
      isLoading.value = false;
      _isLoggingIn = false;
    }
  }
  String _mapAuthError(String message, AppLocalizations l) {
    if (message.contains('Invalid login credentials'))
      return l.invalidCredentials;
    if (message.contains('Email not confirmed')) return l.emailNotVerified;
    return l.signInFailed;
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Use Get.find to avoid duplicate controller instances
    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController());
    }
    _controller = Get.find<LoginController>();
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Row(
          children: [
            Image(
              image: AssetImage("assets/images/gov_logo.webp"),
              width: 40,
              height: 40,
            ),
            SizedBox(width: 20),
            Column(
              children: [
                Text(
                  AppConstants.nepalSarkar,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppConstants.govtOfNepal,
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Obx(() {
              final ct =
                  Get.find<ConnectivityController>().connectionType.value;
              if (ct == ConnectivityResult.none)
                return const ConnectivityIndicator(icon: Icons.signal_wifi_off);
              if (ct == ConnectivityResult.wifi)
                return const ConnectivityIndicator(icon: Icons.wifi);
              if (ct == ConnectivityResult.mobile)
                return const ConnectivityIndicator(
                  icon: Icons.signal_cellular_4_bar,
                );
              return const SizedBox.shrink();
            }),
          ),
          IconButton(onPressed: () {}, icon: const LanguageToggleButton()),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/images/login.json', width: 200, height: 200),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InputField(
                    hintText: "ram@gmail.com",
                    controller: _controller.emailCtrl,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.password,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  PasswordFieldLogin(
                    controller: _controller.passwordCtrl,
                    hintText: "xxxxxxxx",
                    focusNode: _passwordFocus,
                    onSubmitted: () => _controller.login(context),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _controller.resetPassword(context),
                      child: Text(
                        AppLocalizations.of(context)!.forgotPassword,
                        style: const TextStyle(
                          color: AppConstants.secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Obx(
                () => LoginSignupButton(
                  text: AppLocalizations.of(context)!.login,
                  onPressed: _controller.isLoading.value
                      ? null
                      : () => _controller.login(context),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.donthaveanaccout,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                TextButton(
                  onPressed: () => Get.offAll(() => const SignupScreen()),
                  child: Text(
                    AppLocalizations.of(context)!.signup,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              loc.orSignInWith,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 220,
                child: Obx(
                      () => ImageButton(
                    imagePath: 'assets/images/google.png',
                    text: loc.google,
                    onPressed: _controller.isLoading.value
                        ? null
                        : () => _controller.continueWithGoogle(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Password field for login screen (with toggle)
class PasswordFieldLogin extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  const PasswordFieldLogin({
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<PasswordFieldLogin> createState() => _PasswordFieldLoginState();
}

class _PasswordFieldLoginState extends State<PasswordFieldLogin> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      onEditingComplete: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
