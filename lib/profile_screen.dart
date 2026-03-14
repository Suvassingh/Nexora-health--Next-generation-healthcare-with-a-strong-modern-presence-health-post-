import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/controller/locale_conreoller.dart';
import 'package:healthpost_app/models/doctor_model.dart';
import 'package:healthpost_app/verified_batch.dart';
import 'package:healthpost_app/widgets/contact_btn.dart';
import 'package:healthpost_app/widgets/dropdown_inputfield.dart';
import 'package:healthpost_app/widgets/edit_field.dart';
import 'package:healthpost_app/widgets/error_state.dart';
import 'package:healthpost_app/widgets/hero_banner.dart';
import 'package:healthpost_app/widgets/info_record.dart';
import 'package:healthpost_app/widgets/language_tab.dart';
import 'package:healthpost_app/widgets/logout_dialog.dart';
import 'package:healthpost_app/widgets/read_only_field.dart';
import 'package:healthpost_app/widgets/settings.dart';
import 'package:healthpost_app/widgets/shimmer_anim.dart';
import 'package:healthpost_app/widgets/start_stripe.dart';
import 'package:healthpost_app/widgets/stile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/login_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final LocaleController _localeCtrl = Get.put(
    LocaleController(),
    permanent: true,
  );

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

    fetchProfile();
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
    // Basic validation
    if (_fullNameCtrl.text.trim().isEmpty) {
      _showSnack('Full name cannot be empty', isError: true);
      return;
    }
    if (_licenseCtrl.text.trim().isEmpty) {
      _showSnack('NMC license number is required', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Build updates
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

      // Save both tables in parallel
      await Future.wait([
        supabase.from('user_profiles').update(profileUpdate).eq('id', userId),
        supabase.from('doctors').update(doctorUpdate).eq('user_id', userId),
      ]);

      // Refresh model from DB
      await fetchProfile();

      setState(() {
        _editMode = false;
        _saving = false;
      });
      _showSnack('Profile updated successfully');
    } catch (e) {
      setState(() => _saving = false);
      _showSnack('Failed to save: ${e.toString()}', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
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

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: loading
          ? const Shimmer()
          : error != null
          ? ErrorState(
              error: error!,
              onRetry: fetchProfile,
              onSignOut: () async {
                await supabase.auth.signOut();
                Get.offAll(() => LoginScreen());
              },
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: RefreshIndicator(
                  color: AppConstants.primaryColor,
                  onRefresh: _editMode ? () async {} : fetchProfile,
                  child: _buildBody(),
                ),
              ),
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
              label: const Text(
                'Edit',
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
            child: const Text(
              'Cancel',
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
                    label: const Text(
                      'Save',
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
                  const Expanded(
                    child: Text(
                      'Edit mode — tap any field to change it',
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
                  title: 'Personal Details',
                  rows: [
                    IR(
                      Icons.badge_outlined,
                      'Full Name',
                      d.fullName.isEmpty ? '—' : d.fullName,
                    ),
                    IR(
                      Icons.phone_outlined,
                      'Phone',
                      d.phone.isEmpty ? '—' : d.phone,
                    ),
                    IR(
                      Icons.email_outlined,
                      'Email',
                      d.email.isEmpty ? '—' : d.email,
                    ),
                    IR(Icons.wc_rounded, 'Gender', _cap(d.gender)),
                    IR(
                      Icons.cake_outlined,
                      'Date of Birth',
                      _fmtDate(d.dateOfBirth),
                    ),
                    IR(
                      Icons.location_on_outlined,
                      'Municipality',
                      d.municipality ?? '—',
                    ),
                  ],
                ),
          const SizedBox(height: 14),

          _editMode
              ? EditSection(
                  sectionIcon: Icons.local_hospital_outlined,
                  title: 'Professional Details',
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
                  title: 'Professional Details',
                  rows: [
                    IR(
                      Icons.workspace_premium_outlined,
                      'NMC License',
                      d.licenseNumber.isEmpty ? '—' : d.licenseNumber,
                    ),
                    IR(
                      Icons.medical_services_outlined,
                      'Specialty',
                      d.specialty.isEmpty ? '—' : d.specialty,
                    ),
                    IR(
                      Icons.school_outlined,
                      'Qualification',
                      d.qualification.isEmpty ? '—' : d.qualification,
                    ),
                    IR(
                      Icons.timer_outlined,
                      'Experience',
                      d.experienceYears != null
                          ? '${d.experienceYears} years'
                          : '—',
                    ),
                    IR(
                      Icons.home_outlined,
                      'Health Post',
                      d.healthpostName.isEmpty ? '—' : d.healthpostName,
                    ),
                    IR(
                      Icons.calendar_today_outlined,
                      'Doctor Since',
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
                child: const Text(
                  'Editing',
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        EditField(
          icon: Icons.badge_outlined,
          label: 'Full Name *',
          controller: fullNameCtrl,
          hint: 'Enter full name',
          inputType: TextInputType.name,
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        EditField(
          icon: Icons.phone_outlined,
          label: 'Phone',
          controller: phoneCtrl,
          hint: '+977 9XXXXXXXXX',
          inputType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        EditField(
          icon: Icons.location_on_outlined,
          label: 'Municipality',
          controller: municipalityCtrl,
          hint: 'e.g. Kathmandu Metropolitan',
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),

        DropdownInputField(
          hintText: "Select Gender",
          icon: Icons.wc_rounded,
          label: "Gender",
          value: selectedGender,
          display: (v) => v[0].toUpperCase() + v.substring(1),
          items: genderOptions,
          onChanged: onGenderChanged,
        ),
        const SizedBox(height: 14),
        // Email — read-only (managed by Supabase Auth)
        ReadOnlyField(
          icon: Icons.email_outlined,
          label: 'Email (read-only)',
          value: email.isEmpty ? '—' : email,
          note: 'Email is tied to your auth account',
        ),
        const SizedBox(height: 14),
        // DOB — read-only
        ReadOnlyField(
          icon: Icons.cake_outlined,
          label: 'Date of Birth (read-only)',
          value: dateOfBirth,
          note: 'Contact admin to update DOB',
        ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        EditField(
          icon: Icons.workspace_premium_outlined,
          label: 'NMC License Number *',
          controller: licenseCtrl,
          hint: 'e.g. 12345',
          inputType: TextInputType.number,
        ),
        const SizedBox(height: 14),

        DropdownInputField(
          icon: Icons.medical_services_outlined,
          hintText: "select Speciality",
          label: "Speciality",
          value: selectedSpecialty,
          display: (v) => v,

          items: specialtyOptions,
          onChanged: onSpecialtyChanged,
        ),
        const SizedBox(height: 14),
        EditField(
          icon: Icons.school_outlined,
          label: 'Qualification',
          controller: qualificationCtrl,
          hint: 'e.g. MBBS, MD',
          capitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 14),
        EditField(
          icon: Icons.timer_outlined,
          label: 'Years of Experience',
          controller: experienceCtrl,
          hint: 'e.g. 8',
          inputType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        EditField(
          icon: Icons.home_outlined,
          label: 'Health Post Name',
          controller: healthpostCtrl,
          hint: 'e.g. Tokha Health Post',
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        ReadOnlyField(
          icon: Icons.calendar_today_outlined,
          label: 'Doctor Since (read-only)',
          value: doctorSince,
          note: 'Set automatically on registration',
        ),
      ],
    ),
  );
}
