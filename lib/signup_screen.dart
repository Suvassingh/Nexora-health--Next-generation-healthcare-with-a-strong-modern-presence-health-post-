// import 'dart:io';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:get/get.dart';
// import 'package:healthpost_app/app_constants.dart';
// import 'package:healthpost_app/controller/internet_status_controller.dart';
// import 'package:healthpost_app/home_screen.dart';
// import 'package:healthpost_app/l10n/app_localizations.dart';
// import 'package:healthpost_app/login_screen.dart';
// import 'package:healthpost_app/utils/logging.dart';
// import 'package:healthpost_app/widgets/connectivity_icon.dart';
// import 'package:healthpost_app/widgets/dropdown_inputfield.dart';
// import 'package:healthpost_app/widgets/image_button.dart';
// import 'package:healthpost_app/widgets/input_field.dart';
// import 'package:healthpost_app/widgets/language_toggle_button.dart';
// import 'package:healthpost_app/widgets/login_signup_button.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen>
//     with SingleTickerProviderStateMixin {
//   final ConnectivityController controller = Get.put(ConnectivityController());

//   // ── Personal Info controllers ────────────────────────────────────────────
//   final nameController = TextEditingController();
//   final phoneController = TextEditingController();
//   final ageController = TextEditingController();
//   // final addressController = TextEditingController();
//     String? _selectedProvince;
//   String? _selectedDistrict;
//   String? _selectedMunicipality;

//   // ── Doctor-specific controllers ──────────────────────────────────────────
//   final specialtyController =
//       TextEditingController();
//   final licenseNumberController =
//       TextEditingController();
//   final qualificationController = TextEditingController();
//   final experienceYearsController = TextEditingController();
//   final healthpostNameController = TextEditingController();
//   final emailcontroller = TextEditingController();
//   final passwordcontroller = TextEditingController();
//   final confirmPasswordController = TextEditingController();

//   String? selectedGender;
//   String? selectedSpecialty;

//   bool loading = false;

//   late TabController tabController;
//   final supabase = Supabase.instance.client;

//   static const List<String> _specialties = [
//     'General Physician',
//     'Pediatrics',
//     'Gynecology & Obstetrics',
//     'Surgery',
//     'Orthopedics',
//     'Dermatology',
//     'ENT',
//     'Ophthalmology',
//     'Psychiatry',
//     'Dentistry',
//     'Other',
//   ];

//   String get _addressForDb {
//     final parts = [
//       if (_selectedMunicipality != null && _selectedMunicipality!.isNotEmpty)
//         _selectedMunicipality!,
//       if (_selectedDistrict != null) _selectedDistrict!,
//       if (_selectedProvince != null) _selectedProvince!,
//     ];
//     return parts.join(', ');
//   }
//   // ────────────────────────────────────────────────────────────────────────
//   // SIGN UP (email + password)
//   // ────────────────────────────────────────────────────────────────────────
//   Future<void> signUp() async {
//     if (!_validatePersonalFields()) return;
//     if (!_validateDoctorFields()) return;
//     if (!_validateAccountFields()) return;

//     setState(() => loading = true);
//     try {
//       // Step 1 – create auth user
//       final result = await supabase.auth.signUp(
//         email: emailcontroller.text.trim(),
//         password: passwordcontroller.text,
//       );

//       if (result.user == null) {
//         Get.snackbar(
//           'Error',
//           'Sign up failed. Please try again.',
//           backgroundColor: Colors.redAccent,
//           colorText: Colors.white,
//         );
//         return;
//       }

//       final userId = result.user!.id;

//       // Step 2 – save user_profiles (role = doctor)
//       await _saveUserProfile(userId: userId);

//       // Step 3 – save doctors table
//       await _saveDoctorProfile(userId: userId);

//       Get.snackbar(
//         'सफल! / Success',
//         'Doctor account created successfully!',
//         backgroundColor: Colors.green.shade100,
//         duration: const Duration(seconds: 2),
//       );
//       await Future.delayed(const Duration(seconds: 2));
//       Get.offAll(() => LoginScreen());
//     } on AuthException catch (e) {
//       Get.snackbar(
//         'Sign Up Failed',
//         _authErrorMessage(e.message),
//         backgroundColor: Colors.red.shade100,
//       );
//     } catch (e) {
//       Get.snackbar(
//         'Sign Up Failed',
//         e.toString(),
//         backgroundColor: Colors.redAccent,
//       );
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   // ────────────────────────────────────────────────────────────────────────
//   // GOOGLE SIGN IN
//   // ────────────────────────────────────────────────────────────────────────
//   Future<void> continueWithGoogle() async {
//     setState(() => loading = true);
//     try {
//       final signIn = GoogleSignIn.instance;
//       await signIn.initialize(
//         serverClientId: dotenv.env['web_clientid'],
//         clientId: Platform.isAndroid
//             ? dotenv.env['android_clientid']
//             : dotenv.env['ios_clientid'],
//       );

//       final account = await signIn.authenticate();
//       final idToken = account.authentication.idToken ?? '';
//       final authorization =
//           await account.authorizationClient.authorizationForScopes([
//             'email',
//             'profile',
//           ]) ??
//           await account.authorizationClient.authorizeScopes([
//             'email',
//             'profile',
//           ]);

//       final result = await supabase.auth.signInWithIdToken(
//         provider: OAuthProvider.google,
//         idToken: idToken,
//         accessToken: authorization.accessToken,
//       );

//       if (result.user == null) return;

//       final userId = result.user!.id;
//       final googleName =
//           result.user!.userMetadata?['full_name'] ??
//           result.user!.userMetadata?['name'] ??
//           '';
//       final googleAvatar = result.user!.userMetadata?['avatar_url'] ?? '';

//       // Save user_profiles with google metadata merged with form data
//       await supabase.from('user_profiles').upsert({
//         'id': userId,
//         'full_name': nameController.text.trim().isNotEmpty
//             ? nameController.text.trim()
//             : googleName,
//         'phone': phoneController.text.trim().isNotEmpty
//             ? _formatPhone(phoneController.text.trim())
//             : null,
//         'role': 'doctor',
//         'preferred_language': 'nepali',
//         'avatar_url': googleAvatar,
//         'email': result.user!.email ?? '',
//         'updated_at': DateTime.now().toIso8601String(),
//       }, onConflict: 'id');

//       // Save doctors row (only non-null fields)
//       await _saveDoctorProfile(userId: userId);

//       final hasCompleteProfile =
//           nameController.text.trim().isNotEmpty &&
//           licenseNumberController.text.trim().isNotEmpty;

//       Get.offAll(() => HomeScreen());

//       if (!hasCompleteProfile) {
//         Get.snackbar(
//           'प्रोफाइल अपूर्ण',
//           'Please complete your doctor profile in settings.',
//           backgroundColor: Colors.orange.shade100,
//           duration: const Duration(seconds: 4),
//         );
//       }
//     } catch (e) {
//       Get.snackbar(
//         'Google Sign-In Failed',
//         e.toString(),
//         backgroundColor: Colors.red.shade100,
//       );
//       logger(
//         e.toString(),
//         'SignupScreen.continueWithGoogle',
//         level: Level.info,
//       );
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   // ────────────────────────────────────────────────────────────────────────
//   // DB HELPERS
//   // ────────────────────────────────────────────────────────────────────────

//   /// Mirrors the patient app's user_profiles upsert, but role = 'doctor'.
//   Future<void> _saveUserProfile({required String userId}) async {
//     await supabase.from('user_profiles').upsert({
//       'id': userId,
//       'full_name': nameController.text.trim(),
//       'phone': _formatPhone(phoneController.text.trim()),
//       'role': 'doctor', // ← always doctor from this app
//       'preferred_language': 'nepali',
//       'email': emailcontroller.text.trim(),
//       'gender': _mapGender(selectedGender),
//       'date_of_birth': _ageToDateOfBirth(ageController.text.trim()),
//      'municipality': _selectedMunicipality ?? '',
//       'district': _selectedDistrict ?? '',
//       'province': _selectedProvince ?? '',
//       'updated_at': DateTime.now().toIso8601String(),
//     }, onConflict: 'id');
//   }

//   /// Saves doctor-specific fields to the `doctors` table.
//   Future<void> _saveDoctorProfile({required String userId}) async {
//     final data = <String, dynamic>{
//       'user_id': userId,
//       'specialty': selectedSpecialty ?? specialtyController.text.trim(),
//       'license_number': licenseNumberController.text.trim(),
//       'qualification': qualificationController.text.trim(),
//       'healthpost_name': healthpostNameController.text.trim(),
//       'updated_at': DateTime.now().toIso8601String(),
//     };

//     // Experience years – store only if numeric
//     final expYears = int.tryParse(experienceYearsController.text.trim());
//     if (expYears != null) data['experience_years'] = expYears;

//     await supabase.from('doctors').upsert(data, onConflict: 'user_id');
//   }

//   // ────────────────────────────────────────────────────────────────────────
//   // VALIDATION
//   // ────────────────────────────────────────────────────────────────────────
//   bool _validatePersonalFields() {
//     if (nameController.text.trim().isEmpty) {
//       _snackError('Name is required');
//       return false;
//     }
//     if (phoneController.text.trim().isEmpty) {
//       _snackError('Phone is required');
//       return false;
//     }
//     if (ageController.text.trim().isEmpty) {
//       _snackError('Age is required');
//       return false;
//     }
//     if (selectedGender == null) {
//       _snackError('Gender is required');
//       return false;
//     }
//     if (addressController.text.trim().isEmpty) {
//       _snackError('Address is required');
//       return false;
//     }
//     return true;
//   }

//   bool _validateDoctorFields() {
//     if (licenseNumberController.text.trim().isEmpty) {
//       _snackError('NMC License Number is required');
//       return false;
//     }
//     if ((selectedSpecialty == null || selectedSpecialty!.isEmpty) &&
//         specialtyController.text.trim().isEmpty) {
//       _snackError('Specialty is required');
//       return false;
//     }
//     if (qualificationController.text.trim().isEmpty) {
//       _snackError('Qualification is required (e.g. MBBS, MD)');
//       return false;
//     }
//     if (healthpostNameController.text.trim().isEmpty) {
//       _snackError('Healthpost / Hospital name is required');
//       return false;
//     }
//     return true;
//   }

//   bool _validateAccountFields() {
//     if (emailcontroller.text.trim().isEmpty) {
//       _snackError('Email is required');
//       return false;
//     }
//     if (passwordcontroller.text.length < 6) {
//       _snackError('Password must be at least 6 characters');
//       return false;
//     }
//     if (passwordcontroller.text != confirmPasswordController.text) {
//       _snackError('Passwords do not match');
//       return false;
//     }
//     return true;
//   }

//   void _snackError(String message) {
//     Get.snackbar(
//       'Error',
//       message,
//       backgroundColor: Colors.redAccent,
//       colorText: Colors.white,
//     );
//   }

//   // ────────────────────────────────────────────────────────────────────────
//   // UTILITY HELPERS
//   // ────────────────────────────────────────────────────────────────────────
//   String _formatPhone(String phone) {
//     phone = phone.replaceAll(' ', '').replaceAll('-', '');
//     if (phone.startsWith('+977')) return phone;
//     if (phone.startsWith('977')) return '+$phone';
//     if (phone.startsWith('0')) return '+977${phone.substring(1)}';
//     return '+977$phone';
//   }

//   String _mapGender(String? gender) {
//     if (gender == null) return 'other';
//     final lower = gender.toLowerCase();
//     if (lower.contains('male') || lower == 'पुरुष') return 'male';
//     if (lower.contains('female') || lower == 'महिला') return 'female';
//     return 'other';
//   }

//   String? _ageToDateOfBirth(String ageStr) {
//     final age = int.tryParse(ageStr);
//     if (age == null) return null;
//     return '${DateTime.now().year - age}-01-01';
//   }

//   String _authErrorMessage(String message) {
//     if (message.contains('already registered') ||
//         message.contains('User already registered')) {
//       return 'This email is already registered. Please login instead.';
//     }
//     if (message.contains('invalid email')) {
//       return 'Please enter a valid email address.';
//     }
//     return message;
//   }

//   // ────────────────────────────────────────────────────────────────────────
//   // LIFECYCLE
//   // ────────────────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();
//     // 3 tabs: Personal Info | Doctor Info | Account Info
//     tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     tabController.dispose();
//     emailcontroller.dispose();
//     passwordcontroller.dispose();
//     nameController.dispose();
//     phoneController.dispose();
//     ageController.dispose();
//     addressController.dispose();
//     confirmPasswordController.dispose();
//     specialtyController.dispose();
//     licenseNumberController.dispose();
//     qualificationController.dispose();
//     experienceYearsController.dispose();
//     healthpostNameController.dispose();
//     super.dispose();
//   }

//   // ────────────────────────────────────────────────────────────────────────
//   // BUILD
//   // ────────────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLocalizations.of(context)!;

//     return Stack(
//       children: [
//         Scaffold(
//           appBar: AppBar(
//             backgroundColor: AppConstants.primaryColor,
//             bottom: TabBar(
//               controller: tabController,
//               labelColor: Colors.white,
//               unselectedLabelColor: Colors.white70,
//               indicatorColor: AppConstants.whiteColor,
//               tabs: const [
//                 Tab(text: 'Personal Info'),
//                 Tab(text: 'Doctor Info'),
//                 Tab(text: 'Account Info'),
//               ],
//             ),
//             title: const Row(
//               children: [
//                 Image(
//                   image: AssetImage('assets/images/gov_logo.webp'),
//                   width: 40,
//                   height: 40,
//                 ),
//                 SizedBox(width: 20),
//                 Column(
//                   children: [
//                     Text(
//                       AppConstants.nepalSarkar,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Text(
//                       AppConstants.govtOfNepal,
//                       style: TextStyle(fontSize: 10, color: Colors.white),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             iconTheme: const IconThemeData(color: Colors.white),
//             actions: [
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Obx(() {
//                   final ct = controller.connectionType.value;
//                   if (ct == ConnectivityResult.none) {
//                     return ConnectivityIndicator(icon: Icons.signal_wifi_off);
//                   } else if (ct == ConnectivityResult.wifi) {
//                     return ConnectivityIndicator(icon: Icons.wifi);
//                   } else if (ct == ConnectivityResult.mobile) {
//                     return ConnectivityIndicator(
//                       icon: Icons.signal_cellular_4_bar,
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 }),
//               ),
//               IconButton(onPressed: () {}, icon: LanguageToggleButton()),
//             ],
//           ),
//           body: TabBarView(
//             controller: tabController,
//             children: [
//               _buildPersonalInfoTab(loc),
//               _buildDoctorInfoTab(loc),
//               _buildAccountInfoTab(loc),
//             ],
//           ),
//         ),

//         // ── Loading overlay ────────────────────────────────────────────────
//         if (loading)
//           Container(
//             color: Colors.black.withOpacity(0.4),
//             child: const Center(
//               child: Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(24),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(
//                         color: AppConstants.primaryColor,
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'Creating account…',
//                         style: TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   // ── TAB 1 : Personal Info ────────────────────────────────────────────────
//   Widget _buildPersonalInfoTab(AppLocalizations loc) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _label(loc.name),
//           InputField(
//             hintText: 'Ram Bahadur',
//             obscureText: false,
//             controller: nameController,
//           ),
//           const SizedBox(height: 20),
//           _label(loc.phone),
//           InputField(
//             hintText: '98xxxxxxxx',
//             obscureText: false,
//             controller: phoneController,
//           ),
//           const SizedBox(height: 20),
//           _label(loc.age),
//           InputField(
//             hintText: '35',
//             obscureText: false,
//             controller: ageController,
//           ),
//           const SizedBox(height: 20),
//           _label(loc.gender),
//           DropdownInputField(
//             hintText: loc.gender,
//             items: [loc.male, loc.female, loc.others],
//             onChanged: (value) => setState(() => selectedGender = value),
//             value: selectedGender,
//           ),
//           const SizedBox(height: 20),
//           _label(loc.address),
//           InputField(
//             hintText: 'Kathmandu-4, Nepal',
//             obscureText: false,
//             controller: addressController,
//           ),
//           const SizedBox(height: 28),
//           LoginSignupButton(
//             text: loc.next,
//             onPressed: () => tabController.animateTo(1),
//           ),
//           const SizedBox(height: 16),
//           _loginPromptRow(loc),
//           const SizedBox(height: 10),
//           const Center(
//             child: Text(
//               'or signup with',
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Center(
//             child: ImageButton(
//               imagePath: 'assets/images/google.png',
//               text: 'Google',
//               onPressed: continueWithGoogle,
//             ),
//           ),
//           const SizedBox(height: 30),
//         ],
//       ),
//     );
//   }

//   // ── TAB 2 : Doctor Info ──────────────────────────────────────────────────
//   Widget _buildDoctorInfoTab(AppLocalizations loc) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Section header
//           Container(
//             padding: const EdgeInsets.all(12),
//             margin: const EdgeInsets.only(bottom: 20),
//             decoration: BoxDecoration(
//               color: AppConstants.primaryColor.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: AppConstants.primaryColor.withOpacity(0.3),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.local_hospital,
//                   color: AppConstants.primaryColor,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'HealthPost Doctor Registration',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                     color: AppConstants.primaryColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           _label('NMC License Number *'),
//           InputField(
//             hintText: 'e.g. 12345-A',
//             obscureText: false,
//             controller: licenseNumberController,
//           ),
//           const SizedBox(height: 20),

//           _label('Specialty *'),
//           DropdownInputField(
//             hintText: 'Select specialty',
//             items: _specialties,
//             onChanged: (value) => setState(() => selectedSpecialty = value),
//             value: selectedSpecialty,
//           ),
//           const SizedBox(height: 20),

//           _label('Qualification *'),
//           InputField(
//             hintText: 'e.g. MBBS, MD',
//             obscureText: false,
//             controller: qualificationController,
//           ),
//           const SizedBox(height: 20),

//           _label('Years of Experience'),
//           InputField(
//             hintText: 'e.g. 5',
//             obscureText: false,
//             controller: experienceYearsController,
//           ),
//           const SizedBox(height: 20),

//           _label('Assigned Healthpost / Hospital *'),
//           InputField(
//             hintText: 'e.g. Tokha Health Post',
//             obscureText: false,
//             controller: healthpostNameController,
//           ),
//           const SizedBox(height: 28),

//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => tabController.animateTo(0),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppConstants.primaryColor,
//                     side: const BorderSide(color: AppConstants.primaryColor),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text('Back'),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: LoginSignupButton(
//                   text: loc.next,
//                   onPressed: () {
//                     if (_validateDoctorFields()) tabController.animateTo(2);
//                   },
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 30),
//         ],
//       ),
//     );
//   }

//   // ── TAB 3 : Account Info ─────────────────────────────────────────────────
//   Widget _buildAccountInfoTab(AppLocalizations loc) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _label(loc.email),
//           InputField(
//             hintText: 'doctor@gmail.com',
//             obscureText: false,
//             controller: emailcontroller,
//           ),
//           const SizedBox(height: 20),
//           _label(loc.password),
//           InputField(
//             hintText: '••••••••',
//             obscureText: true,
//             controller: passwordcontroller,
//           ),
//           const SizedBox(height: 20),
//           _label(loc.confirmpassword),
//           InputField(
//             hintText: '••••••••',
//             obscureText: true,
//             controller: confirmPasswordController,
//           ),
//           const SizedBox(height: 28),

//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => tabController.animateTo(1),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppConstants.primaryColor,
//                     side: const BorderSide(color: AppConstants.primaryColor),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text('Back'),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: LoginSignupButton(text: loc.signup, onPressed: signUp),
//               ),
//             ],
//           ),
//           const SizedBox(height: 30),
//         ],
//       ),
//     );
//   }

//   // ── Shared UI helpers ────────────────────────────────────────────────────
//   Widget _label(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 14,
//           color: Colors.black87,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   Widget _loginPromptRow(AppLocalizations loc) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           loc.alreadyhaveanaccount,
//           style: const TextStyle(fontSize: 14, color: Colors.black54),
//         ),
//         TextButton(
//           onPressed: () => Get.offAll(LoginScreen()),
//           child: Text(
//             loc.login,
//             style: const TextStyle(
//               fontSize: 14,
//               color: AppConstants.secondaryColor,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

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

  // ── Personal Info controllers ────────────────────────────────────────────
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();

  // ── Address — Province / District / Municipality (replaces plain text) ──
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedMunicipality;

  // ── Doctor-specific controllers ──────────────────────────────────────────
  final licenseNumberController = TextEditingController();
  final qualificationController = TextEditingController();
  final experienceYearsController = TextEditingController();
  final healthpostNameController = TextEditingController();

  // ── Account Info controllers ─────────────────────────────────────────────
  final emailcontroller = TextEditingController();
  final passwordcontroller = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedGender;
  String? selectedSpecialty;

  bool loading = false;

  late TabController tabController;
  final supabase = Supabase.instance.client;

  // ── Available specialties ────────────────────────────────────────────────
  static const List<String> _specialties = [
    'General Physician',
    'Cardiologist',
    'Orthopedic',
    'Pediatrician',
    'Dermatologist',
    'Psychiatrist',
    'Gynecologist',
    'Surgeon',
    'Neurologist',
    'ENT Specialist',
    'Ophthalmologist',
  ];

  // ── Computed address string saved to DB ─────────────────────────────────
  // Stores "Municipality, District, Province" or best available combination
  String get _addressForDb {
    final parts = [
      if (_selectedMunicipality != null && _selectedMunicipality!.isNotEmpty)
        _selectedMunicipality!,
      if (_selectedDistrict != null) _selectedDistrict!,
      if (_selectedProvince != null) _selectedProvince!,
    ];
    return parts.join(', ');
  }

  // ────────────────────────────────────────────────────────────────────────
  // SIGN UP (email + password)
  // ────────────────────────────────────────────────────────────────────────
  Future<void> signUp() async {
    if (!_validatePersonalFields()) return;
    if (!_validateDoctorFields()) return;
    if (!_validateAccountFields()) return;

    setState(() => loading = true);
    try {
      // Step 1 – create auth user
      final result = await supabase.auth.signUp(
        email: emailcontroller.text.trim(),
        password: passwordcontroller.text,
      );

      if (result.user == null) {
        Get.snackbar(
          'Error',
          'Sign up failed. Please try again.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      final userId = result.user!.id;

      // Step 2 – save user_profiles (role = doctor)
      await _saveUserProfile(userId: userId);

      // Step 3 – save doctors table
      await _saveDoctorProfile(userId: userId);

      Get.snackbar(
        'सफल! / Success',
        'Doctor account created successfully!',
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 2),
      );
      await Future.delayed(const Duration(seconds: 2));
      Get.offAll(() => LoginScreen());
    } on AuthException catch (e) {
      Get.snackbar(
        'Sign Up Failed',
        _authErrorMessage(e.message),
        backgroundColor: Colors.red.shade100,
      );
    } catch (e) {
      Get.snackbar(
        'Sign Up Failed',
        e.toString(),
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // GOOGLE SIGN IN
  // ────────────────────────────────────────────────────────────────────────
  Future<void> continueWithGoogle() async {
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

      // Save user_profiles with google metadata merged with form data
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
        Get.snackbar(
          'प्रोफाइल अपूर्ण',
          'Please complete your doctor profile in settings.',
          backgroundColor: Colors.orange.shade100,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Google Sign-In Failed',
        e.toString(),
        backgroundColor: Colors.red.shade100,
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

  // ────────────────────────────────────────────────────────────────────────
  // DB HELPERS
  // ────────────────────────────────────────────────────────────────────────

  /// Saves to user_profiles — role = 'doctor'.
  /// Stores province / district / municipality as separate columns
  /// (requires doctor_location_migration.sql to have been run).
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

  /// Saves doctor-specific fields to the `doctors` table.
  /// Also stores province / district / municipality so the booking screen
  /// can filter by location.
  Future<void> _saveDoctorProfile({required String userId}) async {
    final data = <String, dynamic>{
      'user_id': userId,
      'specialty': selectedSpecialty ?? '',
      'license_number': licenseNumberController.text.trim(),
      'qualification': qualificationController.text.trim(),
      'healthpost_name': healthpostNameController.text.trim(),

      'updated_at': DateTime.now().toIso8601String(),
    };

    final expYears = int.tryParse(experienceYearsController.text.trim());
    if (expYears != null) data['experience_years'] = expYears;

    await supabase.from('doctors').upsert(data, onConflict: 'user_id');
  }

  // ────────────────────────────────────────────────────────────────────────
  // VALIDATION
  // ────────────────────────────────────────────────────────────────────────
  bool _validatePersonalFields() {
    if (nameController.text.trim().isEmpty) {
      _snackError('Name is required');
      return false;
    }
    if (phoneController.text.trim().isEmpty) {
      _snackError('Phone is required');
      return false;
    }
    if (ageController.text.trim().isEmpty) {
      _snackError('Age is required');
      return false;
    }
    if (selectedGender == null) {
      _snackError('Gender is required');
      return false;
    }
    if (_selectedProvince == null) {
      _snackError('Province is required');
      return false;
    }
    if (_selectedDistrict == null) {
      _snackError('District is required');
      return false;
    }
    return true;
  }

  bool _validateDoctorFields() {
    if (licenseNumberController.text.trim().isEmpty) {
      _snackError('NMC License Number is required');
      return false;
    }
    if (selectedSpecialty == null || selectedSpecialty!.isEmpty) {
      _snackError('Specialty is required');
      return false;
    }
    if (qualificationController.text.trim().isEmpty) {
      _snackError('Qualification is required (e.g. MBBS, MD)');
      return false;
    }
    if (healthpostNameController.text.trim().isEmpty) {
      _snackError('Healthpost / Hospital name is required');
      return false;
    }
    return true;
  }

  bool _validateAccountFields() {
    if (emailcontroller.text.trim().isEmpty) {
      _snackError('Email is required');
      return false;
    }
    if (passwordcontroller.text.length < 6) {
      _snackError('Password must be at least 6 characters');
      return false;
    }
    if (passwordcontroller.text != confirmPasswordController.text) {
      _snackError('Passwords do not match');
      return false;
    }
    return true;
  }

  void _snackError(String message) => Get.snackbar(
    'Error',
    message,
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
  );

  // ────────────────────────────────────────────────────────────────────────
  // UTILITY HELPERS
  // ────────────────────────────────────────────────────────────────────────
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
    if (message.contains('already registered') ||
        message.contains('User already registered')) {
      return 'This email is already registered. Please login instead.';
    }
    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    return message;
  }

  // ────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ────────────────────────────────────────────────────────────────────────
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
    healthpostNameController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────────────
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
              tabs: const [
                Tab(text: 'Personal Info'),
                Tab(text: 'Doctor Info'),
                Tab(text: 'Account Info'),
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

        // ── Loading overlay ────────────────────────────────────────────────
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

  // ── TAB 1 : Personal Info ────────────────────────────────────────────────
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

          // ── Address Section ─────────────────────────────────────────────
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

  // ── TAB 2 : Doctor Info ──────────────────────────────────────────────────
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

          _label('Assigned Healthpost / Hospital *'),
          InputField(
            hintText: 'e.g. Tokha Health Post',
            obscureText: false,
            controller: healthpostNameController,
          ),
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── TAB 3 : Account Info ─────────────────────────────────────────────────
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

  // ── Shared UI helpers ────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION DROPDOWN WIDGET
// Reusable styled dropdown for Province / District / Municipality
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION SUMMARY CHIP
// Shows selected Province › District › Municipality as a confirmation row
// ─────────────────────────────────────────────────────────────────────────────
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
