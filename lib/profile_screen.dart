import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/controller/locale_conreoller.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/models/doctor_model.dart';
import 'package:healthpost_app/providers/profile_providers.dart';
import 'package:healthpost_app/services/tts_service.dart';

import 'package:healthpost_app/widgets/dropdown_inputfield.dart';
import 'package:healthpost_app/widgets/edit_field.dart';
import 'package:healthpost_app/widgets/error_state.dart';
import 'package:healthpost_app/widgets/hero_banner.dart';
import 'package:healthpost_app/widgets/info_record.dart';
import 'package:healthpost_app/widgets/logout_dialog.dart';
import 'package:healthpost_app/widgets/read_only_field.dart';
import 'package:healthpost_app/widgets/settings.dart';
import 'package:healthpost_app/widgets/shimmer_anim.dart';
import 'package:healthpost_app/widgets/start_stripe.dart';
import 'package:healthpost_app/widgets/voice_fab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});
  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final LocaleController _localeCtrl = Get.put(
    LocaleController(),
    permanent: true,
  );
AppLocalizations get _l => AppLocalizations.of(context)!;
  DoctorProfileModel? doctor;
  bool loading = true;
  String? error;
  bool _editMode = false;
  bool _saving = false;

  // user_profiles editable fields
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _municipalityCtrl;
  String? _selectedGender;

  // doctors editable fields
  late TextEditingController _licenseCtrl;
  late TextEditingController _qualificationCtrl;
  late TextEditingController _experienceCtrl;
  late TextEditingController _healthpostCtrl;
  String? _selectedSpecialty;

  static const List<String> _genderOptions = ['male', 'female', 'other'];
  static const List<String> _specialtyOptions = [
    'General Physician',
    'Pediatrician',
    'Gynecologist',
    'Surgeon',
    'Orthopedic',
    'Dermatologist',
    'Psychiatrist',
    'Cardiologist',
    'Neurologist',
    'ENT Specialist',
    'Ophthalmologist',
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fullNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _municipalityCtrl = TextEditingController();
    _licenseCtrl = TextEditingController();
    _qualificationCtrl = TextEditingController();
    _experienceCtrl = TextEditingController();
    _healthpostCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _municipalityCtrl.dispose();
    _licenseCtrl.dispose();
    _qualificationCtrl.dispose();
    _experienceCtrl.dispose();
    _healthpostCtrl.dispose();
    TtsService().stop();
    super.dispose();
  }

  void _populateControllers(DoctorProfileModel d) {
    _fullNameCtrl.text = d.fullName;
    _phoneCtrl.text = d.phone;
    _municipalityCtrl.text = d.municipality ?? '';
    _selectedGender = _genderOptions.contains(d.gender) ? d.gender : null;
    _licenseCtrl.text = d.licenseNumber;
    _qualificationCtrl.text = d.qualification;
    _experienceCtrl.text = d.experienceYears?.toString() ?? '';
    _healthpostCtrl.text = d.healthpostName;
    _selectedSpecialty = _specialtyOptions.contains(d.specialty)
        ? d.specialty
        : null;
  }

  Future<void> fetchProfile() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null)
        throw Exception('Not authenticated. Please login again.');

      final results = await Future.wait([
        supabase.from('user_profiles').select().eq('id', userId).maybeSingle(),
        supabase.from('doctors').select().eq('user_id', userId).maybeSingle(),
      ]);

      final profileMap = results[0] as Map<String, dynamic>?;
      final doctorMap = results[1] as Map<String, dynamic>?;

      if (profileMap == null && doctorMap == null)
        throw Exception('no_profile');
      if (profileMap == null) throw Exception('no_user_profile:$userId');
      if (doctorMap == null) throw Exception('no_doctor_profile');

      final lang = profileMap['preferred_language'] ?? 'english';
      _localeCtrl.setLocale(lang == 'nepali' ? 'np' : 'en');

      final model = DoctorProfileModel.fromMaps(
        profile: profileMap,
        doctor: doctorMap,
      );
      _populateControllers(model);

      setState(() {
        doctor = model;
        loading = false;
      });
      _animController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _startEdit() {
    _populateControllers(doctor!);
    setState(() => _editMode = true);
  }

  void _cancelEdit() {
    _populateControllers(doctor!);
    setState(() => _editMode = false);
  }

  Future<void> _saveProfile() async {
    if (_fullNameCtrl.text.trim().isEmpty) {
     _showSnack(_l.fullNameRequired, isError: true);

      return;
    }
    if (_licenseCtrl.text.trim().isEmpty) {
      _showSnack(_l.nmcLicenseRequired, isError: true);

      return;
    }

    setState(() => _saving = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final profileUpdate = <String, dynamic>{
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'municipality': _municipalityCtrl.text.trim(),
        if (_selectedGender != null) 'gender': _selectedGender,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final doctorUpdate = <String, dynamic>{
        'license_number': _licenseCtrl.text.trim(),
        'specialty': _selectedSpecialty ?? doctor!.specialty,
        'qualification': _qualificationCtrl.text.trim(),
        'experience_years': _experienceCtrl.text.trim().isNotEmpty
            ? int.tryParse(_experienceCtrl.text.trim())
            : null,
        'healthpost_name': _healthpostCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Future.wait([
        supabase.from('user_profiles').update(profileUpdate).eq('id', userId),
        supabase.from('doctors').update(doctorUpdate).eq('user_id', userId),
      ]);

      // CHANGED: invalidate provider instead of fetchProfile()
      ref.invalidate(doctorProfileProvider);

      setState(() {
        _editMode = false;
        _saving = false;
      });
_showSnack(_l.profileUpdated);

    } catch (e) {
      setState(() => _saving = false);
      _showSnack('${_l.failedToSave}: ${e.toString()}', isError: true);

    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    Get.snackbar(
      isError ? _l.error : _l.success,
      msg,
      backgroundColor: isError
          ? const Color(0xFFFEF2F2)
          : const Color(0xFFEAF7EF),
      colorText: isError ? const Color(0xFFEF4444) : const Color(0xFF1A7A4A),
      icon: Icon(
        isError
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: isError ? const Color(0xFFEF4444) : const Color(0xFF27AE60),
      ),
      borderRadius: 14,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _saveLanguage(String locale) async {
    _localeCtrl.setLocale(locale);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase
          .from('user_profiles')
          .update({'preferred_language': locale == 'np' ? 'nepali' : 'english'})
          .eq('id', userId);
    } catch (_) {}
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const LogoutDialog(),
    );
    if (ok == true) {
      await supabase.auth.signOut();
      Get.offAll(() => LoginScreen());
    }
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return p.isNotEmpty && p[0].isNotEmpty ? p[0][0].toUpperCase() : 'D';
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso);
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  void _speakProfileGreeting(DoctorProfileModel d, String lang) {
    final isNepali = lang == 'nepali';
    final text = isNepali
        ? 'नमस्ते डाक्टर ${d.fullName}। तपाईंको प्रोफाइल लोड भयो।'
        : 'Hello Dr. ${d.fullName}. Your profile has loaded.';
    TtsService().speak(text);
  }

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _refresh() async {
    ref.invalidate(doctorProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(doctorProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      floatingActionButton: (!_editMode && doctor != null)
          ? VoiceFab(
        language: doctor!.preferredLanguage == 'nepali' ? 'ne-NP' : 'en-US',
        text: doctor!.preferredLanguage == 'nepali'
            ? 'नमस्ते डाक्टर ${doctor!.fullName}। '
            'तपाईंको विशेषज्ञता ${doctor!.specialty} हो। '
            'तपाईंसँग ${doctor!.experienceYears ?? 0} वर्षको अनुभव छ। '
            'तपाईं ${doctor!.healthpostName} मा कार्यरत हुनुहुन्छ।'
            : 'Hello Dr. ${doctor!.fullName}. '
            'Specialty: ${doctor!.specialty}. '
            'Experience: ${doctor!.experienceYears ?? 0} years. '
            'Health post: ${doctor!.healthpostName}.',
      )
          : null,
      body: profileAsync.when(
        loading: () => const Shimmer(),
        error: (e, _) => ErrorState(
          error: e.toString(),
          onRetry: _refresh,
          onSignOut: () async {
            await Supabase.instance.client.auth.signOut();
            Get.offAll(() => LoginScreen());
          },
        ),
        data: (data) {
          // Sync local state on first load or after refresh
          if (doctor == null || doctor != data) {
            // Use addPostFrameCallback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => doctor = data);
                _populateControllers(data);
                // Handle locale
                final lang = data.preferredLanguage ?? 'english';
                _localeCtrl.setLocale(lang == 'nepali' ? 'np' : 'en');
                if (!_animController.isCompleted) _animController.forward();
                _speakProfileGreeting(data, lang);
              }
            });
          }
          if (doctor == null) return const Shimmer(); // first frame guard
          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: RefreshIndicator(
                color: AppConstants.primaryColor,
                onRefresh: _editMode ? () async {} : () async => _refresh(),
                child: _buildBody(),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.primaryColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Row(
        children: [
          Image(
            image: AssetImage('assets/images/gov_logo.webp'),
            width: 36,
            height: 36,
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.nepalSarkar,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                AppConstants.govtOfNepal,
                style: TextStyle(fontSize: 9, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (!_editMode && doctor != null)
          // Edit button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _startEdit,
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: Text(_l.edit,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ),
        if (_editMode) ...[
          // Cancel
          TextButton(
            onPressed: _saving ? null : _cancelEdit,
            child: Text(_l.back,
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          // Save
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _saving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(_l.save,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
            tooltip: 'Read profile aloud',
            onPressed: () {
              if (doctor == null) return;
              final isNepali = (doctor!.preferredLanguage ?? '') == 'nepali';
              final text = isNepali
                  ? 'नाम: ${doctor!.fullName}। '
                        'विशेषज्ञता: ${doctor!.specialty}। '
                        'अनुभव: ${doctor!.experienceYears ?? 0} वर्ष। '
                        'स्वास्थ्य चौकी: ${doctor!.healthpostName}।'
                  : 'Name: ${doctor!.fullName}. '
                        'Specialty: ${doctor!.specialty}. '
                        'Experience: ${doctor!.experienceYears ?? 0} years. '
                        'Health post: ${doctor!.healthpostName}.';
              TtsService().speak(text);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    final d = doctor!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          if (_editMode)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFFBEB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: Color(0xFFF39C12),
                  ),
                  const SizedBox(width: 8),
                   Expanded(
                    child:Text(_l.editModeHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA06000),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelEdit,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFFA06000),
                    ),
                  ),
                ],
              ),
            ),

          HeroBanner(doctor: d, initials: _initials(d.fullName)),
          const SizedBox(height: 16),
          StatsStrip(doctor: d),
          const SizedBox(height: 20),

          _editMode
              ? EditSection(
                  sectionIcon: Icons.person_outline_rounded,
                  title: 'Personal Details',
                  child: _PersonalEditForm(
                    fullNameCtrl: _fullNameCtrl,
                    phoneCtrl: _phoneCtrl,
                    municipalityCtrl: _municipalityCtrl,
                    selectedGender: _selectedGender,
                    genderOptions: _genderOptions,
                    onGenderChanged: (v) => setState(() => _selectedGender = v),
                    email: d.email,
                    dateOfBirth: _fmtDate(d.dateOfBirth),
                  ),
                )
              : InfoCard(
                  sectionIcon: Icons.person_outline_rounded,
                  title: _l.personalDetails,
                  rows: [
                    IR(
                      Icons.badge_outlined,
                     _l.name,
                      d.fullName.isEmpty ? '—' : d.fullName,
                    ),
                    IR(
                      Icons.phone_outlined,
                     _l.phone,
                      d.phone.isEmpty ? '—' : d.phone,
                    ),
                    IR(
                      Icons.email_outlined,
                    _l.email,
                      d.email.isEmpty ? '—' : d.email,
                    ),
                    IR(Icons.wc_rounded, _l.gender, _cap(d.gender)),
                    IR(
                      Icons.cake_outlined,
                      _l.dateOfBirth,
                      _fmtDate(d.dateOfBirth),
                    ),
                    IR(
                      Icons.location_on_outlined,
                     _l.municipality,
                      d.municipality ?? '—',
                    ),
                  ],
                ),
          const SizedBox(height: 14),

          _editMode
              ? EditSection(
                  sectionIcon: Icons.local_hospital_outlined,
                  title: _l.personalDetails,
                  child: _ProfessionalEditForm(
                    licenseCtrl: _licenseCtrl,
                    qualificationCtrl: _qualificationCtrl,
                    experienceCtrl: _experienceCtrl,
                    healthpostCtrl: _healthpostCtrl,
                    selectedSpecialty: _selectedSpecialty,
                    specialtyOptions: _specialtyOptions,
                    onSpecialtyChanged: (v) =>
                        setState(() => _selectedSpecialty = v),
                    doctorSince: _fmtDate(d.doctorSince),
                  ),
                )
              : InfoCard(
                  sectionIcon: Icons.local_hospital_outlined,
                  title: _l.professionalDetails,
                  rows: [
                    IR(
                      Icons.workspace_premium_outlined,
                     _l.nmcLicense,
                      d.licenseNumber.isEmpty ? '—' : d.licenseNumber,
                    ),
                    IR(
                      Icons.medical_services_outlined,
                    _l.specialty,
                      d.specialty.isEmpty ? '—' : d.specialty,
                    ),
                    IR(
                      Icons.school_outlined,
                     _l.qualification,
                      d.qualification.isEmpty ? '—' : d.qualification,
                    ),
                    IR(
                      Icons.timer_outlined,
                     _l.experience,
                      d.experienceYears != null
                          ? '${d.experienceYears} years'
                          : '—',
                    ),
                    IR(
                      Icons.home_outlined,
                      _l.healthPost,
                      d.healthpostName.isEmpty ? '—' : d.healthpostName,
                    ),
                    IR(
                      Icons.calendar_today_outlined,
                    _l.doctorSince,
                      _fmtDate(d.doctorSince),
                    ),
                  ],
                ),
          const SizedBox(height: 14),

          SettingsCard(
            localeCtrl: _localeCtrl,
            onLanguageChanged: _saveLanguage,
            onLogout: _logout,
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class EditSection extends StatelessWidget {
  final IconData sectionIcon;
  final String title;
  final Widget child;

  const EditSection({
    required this.sectionIcon,
    required this.title,
    required this.child,
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
                  color: const Color(0xFFF39C12).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  sectionIcon,
                  size: 16,
                  color: const Color(0xFFF39C12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFF39C12).withOpacity(0.4),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.editing,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA06000),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF39C12).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF39C12).withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    ),
  );
}

class _PersonalEditForm extends StatelessWidget {
  final TextEditingController fullNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController municipalityCtrl;
  final String? selectedGender;
  final List<String> genderOptions;
  final ValueChanged<String?> onGenderChanged;
  final String email;
  final String dateOfBirth;

  const _PersonalEditForm({
    required this.fullNameCtrl,
    required this.phoneCtrl,
    required this.municipalityCtrl,
    required this.selectedGender,
    required this.genderOptions,
    required this.onGenderChanged,
    required this.email,
    required this.dateOfBirth,
  });

  @override
  Widget build(BuildContext context){
    final l = AppLocalizations.of(context)!;

     return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          EditField(
            icon: Icons.badge_outlined,
            label: '${l.name} *',
            controller: fullNameCtrl,
           hint: l.enterFullName,
            inputType: TextInputType.name,
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          EditField(
            icon: Icons.phone_outlined,
           label: l.phone,
            controller: phoneCtrl,
            hint: '+977 9XXXXXXXXX',
            inputType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          EditField(
            icon: Icons.location_on_outlined,
label: l.municipality,            controller: municipalityCtrl,
            hint: 'e.g. Kathmandu Metropolitan',
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          DropdownInputField(
            hintText: l.selectGender,
            icon: Icons.wc_rounded,
            label: l.gender,
            value: selectedGender,
            display: (v) => v[0].toUpperCase() + v.substring(1),
            items: genderOptions,
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 14),

          ReadOnlyField(
            icon: Icons.email_outlined,
           label: '${l.email} (${l.readOnly})',
            value: email.isEmpty ? '—' : email,
           note: l.emailReadOnlyNote,
          ),
          const SizedBox(height: 14),
          // DOB — read-only
          ReadOnlyField(
            icon: Icons.cake_outlined,
           label: '${l.dateOfBirth} (${l.readOnly})',
            value: dateOfBirth,
            note: l.dobReadOnlyNote
          ),
        ],
      ),
    );
  }
}

class _ProfessionalEditForm extends StatelessWidget {
  final TextEditingController licenseCtrl;
  final TextEditingController qualificationCtrl;
  final TextEditingController experienceCtrl;
  final TextEditingController healthpostCtrl;
  final String? selectedSpecialty;
  final List<String> specialtyOptions;
  final ValueChanged<String?> onSpecialtyChanged;
  final String doctorSince;

  const _ProfessionalEditForm({
    required this.licenseCtrl,
    required this.qualificationCtrl,
    required this.experienceCtrl,
    required this.healthpostCtrl,
    required this.selectedSpecialty,
    required this.specialtyOptions,
    required this.onSpecialtyChanged,
    required this.doctorSince,
  });

  @override
  Widget build(BuildContext context){
    final l = AppLocalizations.of(context)!;
 
    return  Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          EditField(
            icon: Icons.workspace_premium_outlined,
            label: '${l.nmcLicense} *',
            controller: licenseCtrl,
            hint: 'e.g. 12345',
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 14),

          DropdownInputField(
            icon: Icons.medical_services_outlined,
            hintText: l.selectSpecialty,
           label: l.specialty,
            value: selectedSpecialty,
            display: (v) => v,

            items: specialtyOptions,
            onChanged: onSpecialtyChanged,
          ),
          const SizedBox(height: 14),
          EditField(
            icon: Icons.school_outlined,
            label: l.qualification,
            controller: qualificationCtrl,
            hint: 'e.g. MBBS, MD',
            capitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 14),
          EditField(
            icon: Icons.timer_outlined,
           label: l.experience,
            controller: experienceCtrl,
            hint: 'e.g. 8',
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          EditField(
            icon: Icons.home_outlined,
            label: l.healthPost,
            controller: healthpostCtrl,
            hint: 'e.g. Tokha Health Post',
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          ReadOnlyField(
            icon: Icons.calendar_today_outlined,
            label: '${l.doctorSince} (${l.readOnly})',
            value: doctorSince,
           note: l.doctorSinceNote
          ),
        ],
      ),
    );
  }
}
