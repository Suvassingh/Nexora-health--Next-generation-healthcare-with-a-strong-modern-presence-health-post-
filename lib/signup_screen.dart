
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/controller/internet_status_controller.dart';
import 'package:healthpost_app/home_screen.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/login_screen.dart';
import 'package:healthpost_app/nepal_location.dart';
import 'package:healthpost_app/utils/logging.dart';
import 'package:healthpost_app/widgets/connectivity_icon.dart';
import 'package:healthpost_app/widgets/dropdown_inputfield.dart';
import 'package:healthpost_app/widgets/image_button.dart';
import 'package:healthpost_app/widgets/input_field.dart';
import 'package:healthpost_app/widgets/language_toggle_button.dart';
import 'package:healthpost_app/widgets/login_signup_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

//  GETX CONTROLLER
class SignupController extends GetxController {
  final supabase = Supabase.instance.client;

  // TextEditingControllers
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPwdCtrl = TextEditingController();
  final licenseCtrl = TextEditingController();
  final qualificationCtrl = TextEditingController();
  final experienceCtrl = TextEditingController();

  // Reactive variables
  final selectedGender = Rx<String?>(null);
  final selectedSpecialty = Rx<String?>(null);
  final selectedProvince = Rx<String?>(null);
  final selectedDistrict = Rx<String?>(null);
  final selectedMunicipality = Rx<String?>(null);
  final selectedHealthpost = Rx<Map<String, dynamic>?>(null);
  final isLoading = false.obs;
  final selectedDob = Rx<DateTime?>(null);

  // For healthpost search
  final allHealthposts = <Map<String, dynamic>>[].obs;
  final filteredHealthposts = <Map<String, dynamic>>[].obs;
  final loadingHealthposts = false.obs;
  final healthpostError = Rx<String?>(null);
  final hpSearchCtrl = TextEditingController();

  final TabController? tabController;
  bool _isSigningUp = false;
  DateTime _lastHealthpostFetch = DateTime(2000);

  SignupController(this.tabController);

  static const List<String> specialties = ['General Physician'];

  
  //  Validation helpers
  
  String? validateEmail(String email) {
    if (email.isEmpty) return 'emailRequired';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(email)) return 'invalidEmail';
    return null;
  }

  // Relaxed phone validation: any 10-digit number after cleaning
  String? validatePhone(String phone) {
    if (phone.isEmpty) return 'phoneRequired';
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length != 10) return 'phoneInvalidLength';
    return null;
  }

  String? validatePassword(String pwd) {
    if (pwd.length < 6) return 'passwordMinSix';
    return null;
  }

  bool validatePersonalFields(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String? error;
    if (nameCtrl.text.trim().isEmpty) {
      error = l.nameRequired;
    } else if ((error = validatePhone(phoneCtrl.text.trim())) != null) {
      error = error == 'phoneRequired' ? l.phoneRequired : l.phoneInvalid;
    } else if (selectedDob.value == null) {
      error = l.ageRequired;
    } else if (selectedGender.value == null) {
      error = l.genderRequired;
    } else if (selectedProvince.value == null) {
      error = l.provinceRequired;
    } else if (selectedDistrict.value == null) {
      error = l.districtRequired;
    }

    // Enforce minimum age 18
    if (selectedDob.value != null) {
      final age = DateTime.now().difference(selectedDob.value!).inDays ~/ 365;
      if (age < 18) error = l.ageMinimum18;
    }

    if (error != null) {
      _snackError(context, error);
      return false;
    }
    return true;
  }

  bool validateDoctorFields(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String? error;
    if (licenseCtrl.text.trim().isEmpty) {
      error = l.nmcLicenseRequired;
    } else if (selectedSpecialty.value == null) {
      error = l.specialtyRequired;
    } else if (qualificationCtrl.text.trim().isEmpty) {
      error = l.qualificationRequired;
    } else if (selectedHealthpost.value == null) {
      error = l.healthpostRequired;
    }

    if (error != null) {
      _snackError(context, error);
      return false;
    }
    return true;
  }

  bool validateAccountFields(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String? error;
    if ((error = validateEmail(emailCtrl.text.trim())) != null) {
      _snackError(
        context,
        error == 'emailRequired' ? l.emailRequired : l.invalidEmail,
      );
      return false;
    }
    if ((error = validatePassword(passwordCtrl.text)) != null) {
      _snackError(
        context,
        error == 'passwordMinSix' ? l.passwordMinSix : l.passwordRequired,
      );
      return false;
    }
    if (passwordCtrl.text != confirmPwdCtrl.text) {
      _snackError(context, l.passwordMismatch);
      return false;
    }
    return true;
  }

  void _snackError(BuildContext context, String message) {
    Get.snackbar(
      AppLocalizations.of(context)!.error,
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  
  //  Data formatting

  String _formatPhone(String phone) {
    phone = phone.replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('+977')) return phone;
    if (phone.startsWith('977')) return '+$phone';
    if (phone.startsWith('0')) return '+977${phone.substring(1)}';
    return '+977$phone';
  }

  String _mapGender(String? gender) {
    if (gender == null) return 'other';
    final lower = gender.toLowerCase();
    if (lower.contains('male') || lower == 'पुरुष') return 'male';
    if (lower.contains('female') || lower == 'महिला') return 'female';
    return 'other';
  }

  
  //  Healthpost fetching & filtering 
  
  Future<void> fetchHealthposts({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        allHealthposts.isNotEmpty &&
        now.difference(_lastHealthpostFetch).inMinutes < 5)
      return;
    loadingHealthposts.value = true;
    healthpostError.value = null;
    try {
      final res = await supabase
          .from('healthposts')
          .select('id, name, district, municipality, ward')
          .eq('is_active', true)
          .order('name');
      allHealthposts.value = List<Map<String, dynamic>>.from(res);
      filteredHealthposts.value = List.from(allHealthposts);
      _lastHealthpostFetch = now;
    } catch (e) {
      healthpostError.value =
          AppLocalizations.of(Get.context!)?.couldNotLoadHealthposts ??
          'Could not load healthposts';
      debugPrint('[Healthpost] fetch error: $e');
    } finally {
      loadingHealthposts.value = false;
    }
  }

  void filterHealthposts(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      filteredHealthposts.value = List.from(allHealthposts);
    } else {
      filteredHealthposts.value = allHealthposts.where((h) {
        final name = (h['name'] as String? ?? '').toLowerCase();
        final district = (h['district'] as String? ?? '').toLowerCase();
        final muni = (h['municipality'] as String? ?? '').toLowerCase();
        return name.contains(q) || district.contains(q) || muni.contains(q);
      }).toList();
    }
  }
  //  Sign up flows
  Future<void> signUp(BuildContext context) async {
    if (_isSigningUp) return;
    if (!validatePersonalFields(context)) return;
    if (!validateDoctorFields(context)) return;
    if (!validateAccountFields(context)) return;

    // Check connectivity before network call
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      Get.snackbar(
        AppLocalizations.of(context)!.error,
        AppLocalizations.of(context)!.noInternetConnection,
      );
      return;
    }

    _isSigningUp = true;
    final l = AppLocalizations.of(context)!;
    isLoading.value = true;
    try {
      final result = await supabase.auth.signUp(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        emailRedirectTo: 'com.example.healthpost_app://login-callback/',
      );
      if (result.user == null) {
        Get.snackbar(
          l.error,
          l.signUpFailed,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }
      final userId = result.user!.id;
      await _saveUserProfile(userId: userId);
      await _saveDoctorProfile(userId: userId);
      await supabase.auth.signOut();

      Get.snackbar(
        l.verifyEmailTitle,
        l.verifyEmailMessage,
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 5),
      );
      Get.offAll(() => LoginScreen());
    } on AuthException catch (e) {
      Get.snackbar(
        l.signUpFailed,
        _authErrorMessage(e.message, l),
        backgroundColor: Colors.red.shade100,
      );
    } catch (e) {
      Get.snackbar(
        l.signUpFailed,
        l.somethingWentWrong,
        backgroundColor: Colors.redAccent,
      );
    } finally {
      isLoading.value = false;
      _isSigningUp = false;
    }
  }

  Future<void> continueWithGoogle(BuildContext context) async {
    if (_isSigningUp) return;
    _isSigningUp = true;
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
      final userId = result.user!.id;
      final googleName =
          result.user!.userMetadata?['full_name'] ??
          result.user!.userMetadata?['name'] ??
          '';
      final googleAvatar = result.user!.userMetadata?['avatar_url'] ?? '';

      await supabase.from('user_profiles').upsert({
        'id': userId,
        'full_name': nameCtrl.text.trim().isNotEmpty
            ? nameCtrl.text.trim()
            : googleName,
        'phone': phoneCtrl.text.trim().isNotEmpty
            ? _formatPhone(phoneCtrl.text.trim())
            : null,
        'role': 'doctor',
        'preferred_language': 'nepali',
        'avatar_url': googleAvatar,
        'email': result.user!.email ?? '',
        'municipality': selectedMunicipality.value ?? '',
        'district': selectedDistrict.value ?? '',
        'province': selectedProvince.value ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      if (!validateDoctorFields(context)) {
        await supabase.auth.signOut();
        Get.snackbar(
          l.incompleteProfile,
          l.completeDoctorProfileHint,
          backgroundColor: Colors.orange,
        );
        isLoading.value = false;
        _isSigningUp = false;
        return;
      }
      await _saveDoctorProfile(userId: userId);
      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar(l.googleSignInFailed, l.somethingWentWrong);
      logger(
        e.toString(),
        'SignupScreen.continueWithGoogle',
        level: Level.info,
      );
    } finally {
      isLoading.value = false;
      _isSigningUp = false;
    }
  }

  Future<void> _saveUserProfile({required String userId}) async {
    await supabase.from('user_profiles').upsert({
      'id': userId,
      'full_name': nameCtrl.text.trim(),
      'phone': _formatPhone(phoneCtrl.text.trim()),
      'role': 'doctor',
      'preferred_language': 'nepali',
      'email': emailCtrl.text.trim(),
      'gender': _mapGender(selectedGender.value),
      'date_of_birth': selectedDob.value?.toIso8601String(),
      "province": selectedProvince.value ?? "",
      "district": selectedDistrict.value ?? "",
      'municipality': selectedMunicipality.value ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> _saveDoctorProfile({required String userId}) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'specialty': selectedSpecialty.value ?? '',
      'license_number': licenseCtrl.text.trim(),
      'qualification': qualificationCtrl.text.trim(),
      'healthpost_id': selectedHealthpost.value?['id'],
      'healthpost_name': selectedHealthpost.value?['name'] ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    };
    final expYears = int.tryParse(experienceCtrl.text.trim());
    if (expYears != null) data['experience_years'] = expYears;
    await supabase.from('doctors').upsert(data, onConflict: 'user_id');
  }

  String _authErrorMessage(String message, AppLocalizations l) {
    if (message.contains('already registered')) return l.emailAlreadyRegistered;
    if (message.contains('invalid email')) return l.invalidEmail;
    return l.signUpFailed;
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPwdCtrl.dispose();
    licenseCtrl.dispose();
    qualificationCtrl.dispose();
    experienceCtrl.dispose();
    hpSearchCtrl.dispose();
    super.onClose();
  }
}


//  SIGNUP SCREEN 

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SignupController _controller;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _dobFocus = FocusNode();
  final FocusNode _genderFocus = FocusNode();
  final FocusNode _provinceFocus = FocusNode();
  final FocusNode _districtFocus = FocusNode();
  final FocusNode _municipalityFocus = FocusNode();
  final FocusNode _licenseFocus = FocusNode();
  final FocusNode _specialtyFocus = FocusNode();
  final FocusNode _qualificationFocus = FocusNode();
  final FocusNode _experienceFocus = FocusNode();
  final FocusNode _healthpostFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPwdFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = SignupController(_tabController);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.onClose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _dobFocus.dispose();
    _genderFocus.dispose();
    _provinceFocus.dispose();
    _districtFocus.dispose();
    _municipalityFocus.dispose();
    _licenseFocus.dispose();
    _specialtyFocus.dispose();
    _qualificationFocus.dispose();
    _experienceFocus.dispose();
    _healthpostFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPwdFocus.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    bool isValid = true;
    if (index == 1 && !_controller.validatePersonalFields(context))
      isValid = false;
    if (index == 2 && !_controller.validateDoctorFields(context))
      isValid = false;
    if (isValid) _tabController.animateTo(index);
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: now.subtract(
        const Duration(days: 365 * 18),
      ), 
    );
    if (picked != null) _controller.selectedDob.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Obx(
      () => Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: AppConstants.primaryColor,
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppConstants.whiteColor,
                tabs: const [
                  Tab(text: 'Personal'),
                  Tab(text: 'Doctor'),
                  Tab(text: 'Account'),
                ],
              ),
              title: const Row(
                children: [
                  Image(
                    image: AssetImage('assets/images/gov_logo.webp'),
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
                      return const ConnectivityIndicator(
                        icon: Icons.signal_wifi_off,
                      );
                    if (ct == ConnectivityResult.wifi)
                      return const ConnectivityIndicator(icon: Icons.wifi);
                    if (ct == ConnectivityResult.mobile)
                      return const ConnectivityIndicator(
                        icon: Icons.signal_cellular_4_bar,
                      );
                    return const SizedBox.shrink();
                  }),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const LanguageToggleButton(),
                ),
              ],
            ),
            body: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalInfoTab(loc),
                _buildDoctorInfoTab(loc),
                _buildAccountInfoTab(loc),
              ],
            ),
          ),
          if (_controller.isLoading.value)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppConstants.primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Creating account…',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.name),
          InputField(
            hintText: 'Ram Bahadur',
            controller: _controller.nameCtrl,
            focusNode: _nameFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () =>
                FocusScope.of(context).requestFocus(_phoneFocus),
          ),
          const SizedBox(height: 20),

          _label(loc.phone),
          InputField(
            hintText: '98xxxxxxxx',
            controller: _controller.phoneCtrl,
            focusNode: _phoneFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _dobFocus.requestFocus(),
          ),
          const SizedBox(height: 20),

          _label('Date of Birth *'),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _controller.selectedDob.value != null
                          ? '${_controller.selectedDob.value!.toLocal()}'.split(
                              ' ',
                            )[0]
                          : 'Select birth date',
                      style: TextStyle(
                        color: _controller.selectedDob.value != null
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _label(loc.gender),
          DropdownInputField(
            hintText: loc.gender,
            items: [loc.male, loc.female, loc.others],
            onChanged: (v) => _controller.selectedGender.value = v,
            value: _controller.selectedGender.value,
          ),
          const SizedBox(height: 24),

          _sectionHeader(
            icon: Icons.location_on_outlined,
            title: 'ठेगाना / Address',
            subtitle: 'प्रदेश, जिल्ला र नगरपालिका छान्नुहोस्',
          ),
          const SizedBox(height: 14),

          _label('प्रदेश / Province *'),
          _LocationDropdown(
            hint: 'प्रदेश छान्नुहोस्',
            value: _controller.selectedProvince.value,
            items: NepalLocation.provinces,
            onChanged: (v) {
              _controller.selectedProvince.value = v;
              _controller.selectedDistrict.value = null;
              _controller.selectedMunicipality.value = null;
            },
          ),
          const SizedBox(height: 16),

          _label('जिल्ला / District *'),
          _LocationDropdown(
            hint: _controller.selectedProvince.value == null
                ? 'पहिले प्रदेश छान्नुहोस्'
                : 'जिल्ला छान्नुहोस्',
            value: _controller.selectedDistrict.value,
            items: _controller.selectedProvince.value != null
                ? NepalLocation.districtsOf(_controller.selectedProvince.value!)
                : [],
            enabled: _controller.selectedProvince.value != null,
            onChanged: (v) {
              _controller.selectedDistrict.value = v;
              _controller.selectedMunicipality.value = null;
            },
          ),
          const SizedBox(height: 16),

          _label('नगरपालिका / Municipality (वैकल्पिक)'),
          _LocationDropdown(
            hint: _controller.selectedDistrict.value == null
                ? 'पहिले जिल्ला छान्नुहोस्'
                : 'नगरपालिका छान्नुहोस्',
            value: _controller.selectedMunicipality.value,
            items: _controller.selectedDistrict.value != null
                ? NepalLocation.municipalitiesOf(
                    _controller.selectedProvince.value ?? '',
                    _controller.selectedDistrict.value!,
                  )
                : [],
            enabled: _controller.selectedDistrict.value != null,
            displayOverride: (v) {
              final t = NepalLocation.typeLabel(v);
              return t.isNotEmpty ? '$v ($t)' : v;
            },
            onChanged: (v) => _controller.selectedMunicipality.value = v,
          ),
          if (_controller.selectedProvince.value != null) ...[
            const SizedBox(height: 12),
            _LocationSummary(
              province: _controller.selectedProvince.value,
              district: _controller.selectedDistrict.value,
              municipality: _controller.selectedMunicipality.value,
            ),
          ],
          const SizedBox(height: 28),
          LoginSignupButton(text: loc.next, onPressed: () => _changeTab(1)),
          const SizedBox(height: 16),
          _loginPromptRow(loc),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'or signup with',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Obx(
              () => ImageButton(
                imagePath: 'assets/images/google.png',
                text: 'Google',
                  isLoading: _controller.isLoading.value,

                onPressed: _controller.isLoading.value
                    ? null
                    : () => _controller.continueWithGoogle(context),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDoctorInfoTab(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'HealthPost Doctor Registration',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          _label('NMC License Number *'),
          InputField(
            hintText: 'e.g. 12345-A',
            controller: _controller.licenseCtrl,
            focusNode: _licenseFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _specialtyFocus.requestFocus(),
          ),
          const SizedBox(height: 20),

          _label('Specialty *'),
          DropdownInputField(
            hintText: 'Select specialty',
            items: SignupController.specialties,
            onChanged: (v) => _controller.selectedSpecialty.value = v,
            value: _controller.selectedSpecialty.value,
          ),
          const SizedBox(height: 20),

          _label('Qualification *'),
          InputField(
            hintText: 'e.g. MBBS, MD',
            controller: _controller.qualificationCtrl,
            focusNode: _qualificationFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _experienceFocus.requestFocus(),
          ),
          const SizedBox(height: 20),

          _label('Years of Experience'),
          InputField(
            hintText: 'e.g. 5',
            controller: _controller.experienceCtrl,
            focusNode: _experienceFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _healthpostFocus.requestFocus(),
          ),
          const SizedBox(height: 20),

          _label('Assigned Healthpost *'),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _openHealthpostPicker(),
            child: Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _controller.selectedHealthpost.value != null
                      ? AppConstants.primaryColor.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _controller.selectedHealthpost.value != null
                        ? AppConstants.primaryColor
                        : AppConstants.primaryColor.withOpacity(0.4),
                    width: _controller.selectedHealthpost.value != null
                        ? 1.5
                        : 1,
                  ),
                ),
                child: _controller.loadingHealthposts.value
                    ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            _controller.selectedHealthpost.value != null
                                ? Icons.local_hospital
                                : Icons.local_hospital_outlined,
                            size: 20,
                            color: _controller.selectedHealthpost.value != null
                                ? AppConstants.primaryColor
                                : Colors.black38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _controller.selectedHealthpost.value?['name'] ??
                                  'Tap to select healthpost',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    _controller.selectedHealthpost.value != null
                                    ? AppConstants.primaryColor
                                    : Colors.black38,
                                fontWeight:
                                    _controller.selectedHealthpost.value != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Icon(
                            _controller.selectedHealthpost.value != null
                                ? Icons.check_circle_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: _controller.selectedHealthpost.value != null
                                ? AppConstants.primaryColor
                                : Colors.black38,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_controller.selectedHealthpost.value != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppConstants.primaryColor.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  [
                        _controller.selectedHealthpost.value!['municipality'],
                        _controller.selectedHealthpost.value!['district'],
                      ]
                      .where((e) => e != null && (e as String).isNotEmpty)
                      .join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.primaryColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _changeTab(0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: const BorderSide(color: AppConstants.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoginSignupButton(
                  text: loc.next,
                  onPressed: () {
                    if (_controller.validateDoctorFields(context))
                      _changeTab(2);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoTab(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.email),
          InputField(
            hintText: 'doctor@gmail.com',
            controller: _controller.emailCtrl,
            focusNode: _emailFocus,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 20),

          _label(loc.password),
          PasswordField(
            controller: _controller.passwordCtrl,
            hintText: '••••••••',
            focusNode: _passwordFocus,
            onSubmitted: () => _confirmPwdFocus.requestFocus(),
          ),
          const SizedBox(height: 20),

          _label(loc.confirmpassword),
          PasswordField(
            controller: _controller.confirmPwdCtrl,
            hintText: '••••••••',
            focusNode: _confirmPwdFocus,
            onSubmitted: () => _controller.signUp(context),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _changeTab(1),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: const BorderSide(color: AppConstants.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LoginSignupButton(
                  text: loc.signup,
                  onPressed: () => _controller.signUp(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _openHealthpostPicker() async {
    await _controller.fetchHealthposts();
    if (!mounted) return;
    _controller.hpSearchCtrl.clear();
    _controller.filterHealthposts('');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          void filterAndUpdate(String q) {
            final lower = q.toLowerCase().trim();
            final filtered = lower.isEmpty
                ? List<Map<String, dynamic>>.from(_controller.allHealthposts)
                : _controller.allHealthposts.where((h) {
                    final name = (h['name'] as String? ?? '').toLowerCase();
                    final dist = (h['district'] as String? ?? '').toLowerCase();
                    final muni = (h['municipality'] as String? ?? '')
                        .toLowerCase();
                    return name.contains(lower) ||
                        dist.contains(lower) ||
                        muni.contains(lower);
                  }).toList();
            setModal(() => _controller.filteredHealthposts.value = filtered);
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollCtrl) => Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        color: AppConstants.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.selectHealthpost,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (_controller.healthpostError.value != null)
                        TextButton.icon(
                          onPressed: () async {
                            setModal(
                              () => _controller.loadingHealthposts.value = true,
                            );
                            await _controller.fetchHealthposts(
                              forceRefresh: true,
                            );
                            setModal(() {});
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(AppLocalizations.of(context)!.retry),
                        ),
                      if (_controller.healthpostError.value == null &&
                          !_controller.loadingHealthposts.value)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_controller.filteredHealthposts.length} ${AppLocalizations.of(context)!.found}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _controller.hpSearchCtrl,
                    autofocus:
                        _controller.allHealthposts.isNotEmpty &&
                        _controller.healthpostError.value == null,
                    enabled:
                        !_controller.loadingHealthposts.value &&
                        _controller.healthpostError.value == null,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHealthpost,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: ValueListenableBuilder(
                        valueListenable: _controller.hpSearchCtrl,
                        builder: (_, v, __) => v.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _controller.hpSearchCtrl.clear();
                                  filterAndUpdate('');
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppConstants.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: filterAndUpdate,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Obx(() {
                    if (_controller.loadingHealthposts.value) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context)!.loadingHealthposts,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      );
                    }
                    if (_controller.healthpostError.value != null) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _controller.healthpostError.value!,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    if (_controller.filteredHealthposts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.noHealthpostsFound,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: _controller.filteredHealthposts.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 60),
                      itemBuilder: (_, i) {
                        final hp = _controller.filteredHealthposts[i];
                        final isSelected =
                            _controller.selectedHealthpost.value?['id'] ==
                            hp['id'];
                        final sub = [hp['municipality'], hp['district']]
                            .where((e) => e != null && (e as String).isNotEmpty)
                            .join(', ');
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppConstants.primaryColor
                                : AppConstants.primaryColor.withOpacity(0.08),
                            child: Icon(
                              Icons.local_hospital_outlined,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : AppConstants.primaryColor,
                            ),
                          ),
                          title: Text(
                            hp['name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                          subtitle: sub.isNotEmpty
                              ? Text(sub, style: const TextStyle(fontSize: 12))
                              : null,
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: AppConstants.primaryColor,
                                )
                              : Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                          onTap: () {
                            _controller.selectedHealthpost.value = hp;
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppConstants.primaryColor.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppConstants.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _loginPromptRow(AppLocalizations loc) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        loc.alreadyhaveanaccount,
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
      TextButton(
        onPressed: () => Get.offAll(() => LoginScreen()),
        child: Text(
          loc.login,
          style: const TextStyle(
            fontSize: 14,
            color: AppConstants.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}


//  Helper widgets

class _LocationDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final String Function(String)? displayOverride;
  const _LocationDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.displayOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? AppConstants.primaryColor.withOpacity(0.4)
              : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value != null && items.contains(value)) ? value : null,
          isExpanded: true,
          icon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? AppConstants.primaryColor : Colors.grey.shade400,
            ),
          ),
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 14,
                color: enabled ? Colors.black54 : Colors.grey.shade400,
              ),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      displayOverride != null ? displayOverride!(item) : item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _LocationSummary extends StatelessWidget {
  final String? province, district, municipality;
  const _LocationSummary({
    required this.province,
    required this.district,
    required this.municipality,
  });

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (municipality != null && municipality!.isNotEmpty) municipality!,
      if (district != null) district!,
      if (province != null) province!,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 16,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parts.join(' › '),
              style: const TextStyle(
                fontSize: 13,
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Password field with visibility toggle
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  const PasswordField({
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      textInputAction: TextInputAction.next,
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
