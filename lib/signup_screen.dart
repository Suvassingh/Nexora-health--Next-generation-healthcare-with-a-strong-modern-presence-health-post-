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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final ConnectivityController controller = Get.put(ConnectivityController());

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedMunicipality;

  final licenseNumberController = TextEditingController();
  final qualificationController = TextEditingController();
  final experienceYearsController = TextEditingController();
  List<Map<String, dynamic>> _allHealthposts = [];
  List<Map<String, dynamic>> _filteredHealthposts = [];
  Map<String, dynamic>? _selectedHealthpost;
  bool _loadingHealthposts = false;
  bool _healthpostsLoaded = false;
  String? _healthpostError;
  final _hpSearchCtrl = TextEditingController();
  final emailcontroller = TextEditingController();
  final passwordcontroller = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedGender;
  String? selectedSpecialty;

  bool loading = false;

  late TabController tabController;
  final supabase = Supabase.instance.client;

  static const List<String> _specialties = ['General Physician'];
 late final displayed = _filteredHealthposts;

  String get _addressForDb {
    final parts = [
      if (_selectedMunicipality != null && _selectedMunicipality!.isNotEmpty)
        _selectedMunicipality!,
      if (_selectedDistrict != null) _selectedDistrict!,
      if (_selectedProvince != null) _selectedProvince!,
    ];
    return parts.join(', ');
  }

  Future<void> _fetchHealthposts({bool forceRefresh = false}) async {
    if (_healthpostsLoaded && !forceRefresh) return;

    setState(() {
      _loadingHealthposts = true;
      _healthpostError = null;
    });

    try {
      final res = await supabase
          .from('healthposts')
          .select('id, name, district, municipality, ward')
          .eq('is_active', true)
          .order('name');

      _allHealthposts = (res as List).cast<Map<String, dynamic>>();
      _filteredHealthposts = List.from(_allHealthposts);
      _healthpostsLoaded = true;          
      _healthpostError = null;
    } catch (e) {
      _healthpostsLoaded = false;         
      _healthpostError = AppLocalizations.of(context)!.couldNotLoadHealthposts;
      debugPrint('[Healthpost] fetch error: $e');
    } finally {
      if (mounted) setState(() => _loadingHealthposts = false);
    }
  }


  void _filterHealthposts(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filteredHealthposts = q.isEmpty
          ? List.from(_allHealthposts)
          : _allHealthposts.where((h) {
        final name = (h['name'] as String? ?? '').toLowerCase();
        final district = (h['district'] as String? ?? '').toLowerCase();
        final muni = (h['municipality'] as String? ?? '').toLowerCase();
        return name.contains(q) ||
            district.contains(q) ||
            muni.contains(q);
      }).toList();
    });
  }

  Future<void> _openHealthpostPicker() async {
 
    await _fetchHealthposts();
    if (!mounted) return;
    _hpSearchCtrl.clear();
    _filteredHealthposts = List.from(_allHealthposts);

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
                ? List<Map<String, dynamic>>.from(_allHealthposts)
                : _allHealthposts.where((h) {
              final name = (h['name'] as String? ?? '').toLowerCase();
              final dist = (h['district'] as String? ?? '').toLowerCase();
              final muni =
              (h['municipality'] as String? ?? '').toLowerCase();
              return name.contains(lower) ||
                  dist.contains(lower) ||
                  muni.contains(lower);
            }).toList();
            setModal(() => _filteredHealthposts = filtered);
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollCtrl) => Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.local_hospital,
                          color: AppConstants.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.selectHealthpost, 
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      // Retry button shown only on error
                      if (_healthpostError != null)
                        TextButton.icon(
                          onPressed: () async {
                            setModal(() {
                              _loadingHealthposts = true;
                              _healthpostError = null;
                            });
                            try {
                              final res = await supabase
                                  .from('healthposts')
                                  .select('id, name, district, municipality, ward')
                                  .eq('is_active', true)
                                  .order('name');
                              _allHealthposts = (res as List).cast<Map<String, dynamic>>();
                              setModal(() {
                                _filteredHealthposts = List.from(_allHealthposts);
                                _loadingHealthposts = false;
                                _healthpostError = null;
                              });
                            } catch (e) {
                              setModal(() {
                                _loadingHealthposts = false;
                                _healthpostError = 'Could not load healthposts. Tap to retry.';

                              });

                            }

                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(AppLocalizations.of(context)!.retry),

                          style: TextButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                          ),
                        ),
                      // Count badge
                      if (_healthpostError == null && !_loadingHealthposts)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${displayed.length} ${AppLocalizations.of(context)!.found}',
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

                // Search field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _hpSearchCtrl,
                    autofocus: _healthpostsLoaded && _healthpostError == null,
                    enabled: !_loadingHealthposts && _healthpostError == null,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHealthpost,

                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: ValueListenableBuilder(
                        valueListenable: _hpSearchCtrl,
                        builder: (_, v, __) => v.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _hpSearchCtrl.clear();
                            filterAndUpdate('');
                          },
                        )
                            : const SizedBox.shrink(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppConstants.primaryColor, width: 1.5),
                      ),
                    ),
                    onChanged: filterAndUpdate, 
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: _loadingHealthposts
                      ?  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(AppLocalizations.of(context)!.loadingHealthposts,                             style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                      : _healthpostError != null
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off,
                            size: 48,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _healthpostError!,
                          style: TextStyle(
                              color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                      : _filteredHealthposts.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.noHealthpostsFound,
                          style: TextStyle(
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                      : ListView.separated(
                    controller: scrollCtrl,
                    itemCount: _filteredHealthposts.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 60),
                    itemBuilder: (_, i) {
                      final hp = _filteredHealthposts[i];
                      final isSelected =
                          _selectedHealthpost?['id'] ==
                              hp['id'];
                      final sub = [
                        hp['municipality'],
                        hp['district']
                      ]
                          .where((e) =>
                      e != null &&
                          (e as String).isNotEmpty)
                          .join(', ');

                      return ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppConstants.primaryColor
                              : AppConstants.primaryColor
                              .withOpacity(0.08),
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
                            ? Text(sub,
                            style: const TextStyle(
                                fontSize: 12))
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                            color: AppConstants.primaryColor)
                            : Icon(Icons.chevron_right,
                            color: Colors.grey.shade400,
                            size: 20),
                        onTap: () {
                          setState(
                                  () => _selectedHealthpost = hp);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> signUp() async {
    if (!_validatePersonalFields()) return;
    if (!_validateDoctorFields()) return;
    if (!_validateAccountFields()) return;

    final l = AppLocalizations.of(context)!; 
    setState(() => loading = true);
    try {
      final result = await supabase.auth.signUp(
        email: emailcontroller.text.trim(),
        password: passwordcontroller.text,
      );

      if (result.user == null) {
              Get.snackbar(l.error, l.signUpFailed,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      final userId = result.user!.id;

      await _saveUserProfile(userId: userId);

      await _saveDoctorProfile(userId: userId);

         Get.snackbar(l.success, l.doctorAccountCreated,
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 2),
      );
      await Future.delayed(const Duration(seconds: 2));
      Get.offAll(() => LoginScreen());
    } on AuthException catch (e) {
          Get.snackbar(l.signUpFailed, _authErrorMessage(e.message), 
        backgroundColor: Colors.red.shade100,
      );
    } catch (e) {
         Get.snackbar(l.signUpFailed, e.toString(),
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> continueWithGoogle() async {
    final l = AppLocalizations.of(context)!; 
    setState(() => loading = true);
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
      final authorization =
          await account.authorizationClient.authorizationForScopes([
            'email',
            'profile',
          ]) ??
          await account.authorizationClient.authorizeScopes([
            'email',
            'profile',
          ]);

      final result = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
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
        'full_name': nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : googleName,
        'phone': phoneController.text.trim().isNotEmpty
            ? _formatPhone(phoneController.text.trim())
            : null,
        'role': 'doctor',
        'preferred_language': 'nepali',
        'avatar_url': googleAvatar,
        'email': result.user!.email ?? '',
        'municipality': _selectedMunicipality ?? '',
        'district': _selectedDistrict ?? '',
        'province': _selectedProvince ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      await _saveDoctorProfile(userId: userId);

      final hasCompleteProfile =
          nameController.text.trim().isNotEmpty &&
          licenseNumberController.text.trim().isNotEmpty;

      Get.offAll(() => HomeScreen());

      if (!hasCompleteProfile) {
            Get.snackbar(l.incompleteProfile, l.completeDoctorProfileHint,
          backgroundColor: Colors.orange.shade100,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        AppLocalizations.of(context)!.googleSignInFailed,
        e.toString(),
      );
      logger(
        e.toString(),
        'SignupScreen.continueWithGoogle',
        level: Level.info,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveUserProfile({required String userId}) async {
    await supabase.from('user_profiles').upsert({
      'id': userId,
      'full_name': nameController.text.trim(),
      'phone': _formatPhone(phoneController.text.trim()),
      'role': 'doctor',
      'preferred_language': 'nepali',
      'email': emailcontroller.text.trim(),
      'gender': _mapGender(selectedGender),
      'date_of_birth': _ageToDateOfBirth(ageController.text.trim()),
      "province": _selectedProvince ?? "",
      "district": _selectedDistrict ?? "",
      'municipality': _selectedMunicipality ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> _saveDoctorProfile({required String userId}) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'specialty': selectedSpecialty ?? '',
      'license_number': licenseNumberController.text.trim(),
      'qualification': qualificationController.text.trim(),
      'healthpost_id': _selectedHealthpost?['id'],
      'healthpost_name': _selectedHealthpost?['name'] ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    };

    final expYears = int.tryParse(experienceYearsController.text.trim());
    if (expYears != null) data['experience_years'] = expYears;

    await supabase.from('doctors').upsert(data, onConflict: 'user_id');
  }

  bool _validatePersonalFields() {
    final l = AppLocalizations.of(context)!;

    if (nameController.text.trim().isEmpty) {
_snackError(l.nameRequired);
      return false;
    }
    if (phoneController.text.trim().isEmpty) {
     _snackError(l.phoneRequired);

      return false;
    }
    if (ageController.text.trim().isEmpty) {
     _snackError(l.ageRequired);
      return false;
    }
    if (selectedGender == null) {
      _snackError(l.genderRequired);
      return false;
    }
    if (_selectedProvince == null) {
      _snackError(l.provinceRequired);
      return false;
    }
    if (_selectedDistrict == null) {
      _snackError(l.districtRequired);
      return false;
    }
    return true;
  }

  bool _validateDoctorFields() {
    final l = AppLocalizations.of(context)!;

    if (licenseNumberController.text.trim().isEmpty) {
      _snackError(l.nmcLicenseRequired);

      return false;
    }
    if (selectedSpecialty == null || selectedSpecialty!.isEmpty) {
_snackError(l.specialtyRequired);
      return false;
    }
   if (qualificationController.text.trim().isEmpty) {
      _snackError(l.qualificationRequired);
      return false;
    }
    if (_selectedHealthpost == null) {
     _snackError(l.healthpostRequired);

      return false;
    }
    return true;
  }

  bool _validateAccountFields() {
        final l = AppLocalizations.of(context)!;

    if (emailcontroller.text.trim().isEmpty) {
_snackError(l.emailRequired);
      return false;
    }
    if (passwordcontroller.text.length < 6) {
     _snackError(l.passwordMinSix);

      return false;
    }
    if (passwordcontroller.text != confirmPasswordController.text) {
_snackError(l.passwordMismatch);
      return false;
    }
    return true;
  }

  void _snackError(String message) => Get.snackbar(AppLocalizations.of(context)!.error, message,
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
  );

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

  String? _ageToDateOfBirth(String ageStr) {
    final age = int.tryParse(ageStr);
    if (age == null) return null;
    return '${DateTime.now().year - age}-01-01';
  }

  String _authErrorMessage(String message) {
    final l = AppLocalizations.of(context)!;

    if (message.contains('already registered')) {
      return l.emailAlreadyRegistered;
    }
  if (message.contains('invalid email')) {
      return l.invalidEmail;
    }
    return message;
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    emailcontroller.dispose();
    passwordcontroller.dispose();
    nameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    confirmPasswordController.dispose();
    licenseNumberController.dispose();
    qualificationController.dispose();
    experienceYearsController.dispose();
    _hpSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: AppConstants.primaryColor,
            bottom: TabBar(
              controller: tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: AppConstants.whiteColor,
              tabs: [
                Tab(text: loc.personalInfo),
                Tab(text: loc.doctorInfo),
                Tab(text: loc.accountInfo),
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
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Obx(() {
                  final ct = controller.connectionType.value;
                  if (ct == ConnectivityResult.none)
                    return ConnectivityIndicator(icon: Icons.signal_wifi_off);
                  if (ct == ConnectivityResult.wifi)
                    return ConnectivityIndicator(icon: Icons.wifi);
                  if (ct == ConnectivityResult.mobile)
                    return ConnectivityIndicator(
                      icon: Icons.signal_cellular_4_bar,
                    );
                  return const SizedBox.shrink();
                }),
              ),
              IconButton(onPressed: () {}, icon: LanguageToggleButton()),
            ],
          ),
          body: TabBarView(
            controller: tabController,
            children: [
              _buildPersonalInfoTab(loc),
              _buildDoctorInfoTab(loc),
              _buildAccountInfoTab(loc),
            ],
          ),
        ),

        if (loading)
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
    );
  }

  //  TAB 1 : Personal Info 
  Widget _buildPersonalInfoTab(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.name),
          InputField(
            hintText: 'Ram Bahadur',
            obscureText: false,
            controller: nameController,
          ),
          const SizedBox(height: 20),

          _label(loc.phone),
          InputField(
            hintText: '98xxxxxxxx',
            obscureText: false,
            controller: phoneController,
          ),
          const SizedBox(height: 20),

          _label(loc.age),
          InputField(
            hintText: '35',
            obscureText: false,
            controller: ageController,
          ),
          const SizedBox(height: 20),

          _label(loc.gender),
          DropdownInputField(
            hintText: loc.gender,
            items: [loc.male, loc.female, loc.others],
            onChanged: (value) => setState(() => selectedGender = value),
            value: selectedGender,
          ),
          const SizedBox(height: 24),

          //  Address Section 
          _sectionHeader(
            icon: Icons.location_on_outlined,
            title: 'ठेगाना / Address',
            subtitle: 'प्रदेश, जिल्ला र नगरपालिका छान्नुहोस्',
          ),
          const SizedBox(height: 14),

          // Province
          _label('प्रदेश / Province *'),
          _LocationDropdown(
            hint: 'प्रदेश छान्नुहोस्',
            value: _selectedProvince,
            items: NepalLocation.provinces,
            onChanged: (v) => setState(() {
              _selectedProvince = v;
              _selectedDistrict = null;
              _selectedMunicipality = null;
            }),
          ),
          const SizedBox(height: 16),

          // District
          _label('जिल्ला / District *'),
          _LocationDropdown(
            hint: _selectedProvince == null
                ? 'पहिले प्रदेश छान्नुहोस्'
                : 'जिल्ला छान्नुहोस्',
            value: _selectedDistrict,
            items: _selectedProvince != null
                ? NepalLocation.districtsOf(_selectedProvince!)
                : [],
            enabled: _selectedProvince != null,
            onChanged: (v) => setState(() {
              _selectedDistrict = v;
              _selectedMunicipality = null;
            }),
          ),
          const SizedBox(height: 16),

          // Municipality (optional)
          _label('नगरपालिका / Municipality (वैकल्पिक)'),
          _LocationDropdown(
            hint: _selectedDistrict == null
                ? 'पहिले जिल्ला छान्नुहोस्'
                : 'नगरपालिका छान्नुहोस्',
            value: _selectedMunicipality,
            items: _selectedDistrict != null
                ? NepalLocation.municipalitiesOf(
                    _selectedProvince ?? '',
                    _selectedDistrict!,
                  )
                : [],
            enabled: _selectedDistrict != null,
            displayOverride: (v) {
              final t = NepalLocation.typeLabel(v);
              return t.isNotEmpty ? '$v ($t)' : v;
            },
            onChanged: (v) => setState(() => _selectedMunicipality = v),
          ),

          // Selected location summary
          if (_selectedProvince != null) ...[
            const SizedBox(height: 12),
            _LocationSummary(
              province: _selectedProvince,
              district: _selectedDistrict,
              municipality: _selectedMunicipality,
            ),
          ],

          const SizedBox(height: 28),
          LoginSignupButton(
            text: loc.next,
            onPressed: () => tabController.animateTo(1),
          ),
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
            child: ImageButton(
              imagePath: 'assets/images/google.png',
              text: 'Google',
              onPressed: continueWithGoogle,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  //  TAB 2 : Doctor Info 
  Widget _buildDoctorInfoTab(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
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
            obscureText: false,
            controller: licenseNumberController,
          ),
          const SizedBox(height: 20),

          _label('Specialty *'),
          DropdownInputField(
            hintText: 'Select specialty',
            items: _specialties,
            onChanged: (value) => setState(() => selectedSpecialty = value),
            value: selectedSpecialty,
          ),
          const SizedBox(height: 20),

          _label('Qualification *'),
          InputField(
            hintText: 'e.g. MBBS, MD',
            obscureText: false,
            controller: qualificationController,
          ),
          const SizedBox(height: 20),

          _label('Years of Experience'),
          InputField(
            hintText: 'e.g. 5',
            obscureText: false,
            controller: experienceYearsController,
          ),
          const SizedBox(height: 20),

          _label('Assigned Healthpost *'),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _loadingHealthposts ? null : _openHealthpostPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _selectedHealthpost != null
                    ? AppConstants.primaryColor.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedHealthpost != null
                      ? AppConstants.primaryColor
                      : AppConstants.primaryColor.withOpacity(0.4),
                  width: _selectedHealthpost != null ? 1.5 : 1,
                ),
              ),
              child: _loadingHealthposts
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
                          _selectedHealthpost != null
                              ? Icons.local_hospital
                              : Icons.local_hospital_outlined,
                          size: 20,
                          color: _selectedHealthpost != null
                              ? AppConstants.primaryColor
                              : Colors.black38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedHealthpost?['name'] ??
                                'Tap to select healthpost',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedHealthpost != null
                                  ? AppConstants.primaryColor
                                  : Colors.black38,
                              fontWeight: _selectedHealthpost != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Icon(
                          _selectedHealthpost != null
                              ? Icons.check_circle_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _selectedHealthpost != null
                              ? AppConstants.primaryColor
                              : Colors.black38,
                        ),
                      ],
                    ),
            ),
          ),
          if (_selectedHealthpost != null) ...[
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
                        _selectedHealthpost!['municipality'],
                        _selectedHealthpost!['district'],
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
                  onPressed: () => tabController.animateTo(0),
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
              const SizedBox(width: 12), // add space

              Expanded(
                child: LoginSignupButton(
                  text: loc.next,
                  onPressed: () {
                    if (_validateDoctorFields()) tabController.animateTo(2);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //  TAB 3 : Account Info 
  Widget _buildAccountInfoTab(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.email),
          InputField(
            hintText: 'doctor@gmail.com',
            obscureText: false,
            controller: emailcontroller,
          ),
          const SizedBox(height: 20),

          _label(loc.password),
          InputField(
            hintText: '••••••••',
            obscureText: true,
            controller: passwordcontroller,
          ),
          const SizedBox(height: 20),

          _label(loc.confirmpassword),
          InputField(
            hintText: '••••••••',
            obscureText: true,
            controller: confirmPasswordController,
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => tabController.animateTo(1),
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
                child: LoginSignupButton(text: loc.signup, onPressed: signUp),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  //  Shared UI helpers 
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
        onPressed: () => Get.offAll(LoginScreen()),
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
