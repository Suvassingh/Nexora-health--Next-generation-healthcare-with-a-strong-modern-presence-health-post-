import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/widgets/home_appointment.dart';
import 'package:healthpost_app/widgets/home_hero_header.dart';
import 'package:healthpost_app/widgets/home_simmer.dart';
import 'package:healthpost_app/widgets/home_stat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/widgets/connectivity_icon.dart';
import 'package:healthpost_app/widgets/language_toggle_button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:healthpost_app/controller/internet_status_controller.dart';



class HomeStats {
  final int todayPatients;
  final int pending;
  final int completed;
  final int totalThisMonth;

  const HomeStats({
    this.todayPatients = 0,
    this.pending = 0,
    this.completed = 0,
    this.totalThisMonth = 0,
  });
}

class AppointmentItem {
  final String id;
  final String patientName;
  final String reason;
  final String time;
  final String status; // 'pending' | 'confirmed' | 'completed'
  final String? patientInitials;

  const AppointmentItem({
    required this.id,
    required this.patientName,
    required this.reason,
    required this.time,
    required this.status,
    this.patientInitials,
  });

  factory AppointmentItem.fromMap(Map<String, dynamic> m) {
    final patientName =
        m['patients']?['user_profiles']?['full_name'] ?? 'Unknown';
    final initials = _initials(patientName);
    return AppointmentItem(
      id: m['id']?.toString() ?? '',
      patientName: patientName,
      reason: m['reason'] ?? 'General Consultation',
      time: _formatTime(m['scheduled_at']),
      status: m['status'] ?? 'pending',
      patientInitials: initials,
    );
  }

  static String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return p.isNotEmpty && p[0].isNotEmpty ? p[0][0].toUpperCase() : '?';
  }

  static String _formatTime(dynamic iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      final ampm = d.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }
}

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final ConnectivityController connectivityController = Get.put(
    ConnectivityController(),
  );

  // Doctor info (from user_profiles + doctors)
  String _doctorName = '';
  String _specialty = '';
  String _healthpostName = '';
  String? _avatarUrl;

  // Stats
  HomeStats _stats = const HomeStats();

  // Appointments
  List<AppointmentItem> _appointments = [];
  List<Map<String, dynamic>> _recentActivity = [];

  bool _loading = true;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchHomeData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchHomeData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // ── Step 1: Doctor info (these tables always exist) ──────────────────
      final profileResults = await Future.wait([
        supabase
            .from('user_profiles')
            .select('full_name, avatar_url, preferred_language')
            .eq('id', userId)
            .maybeSingle(),
        supabase
            .from('doctors')
            .select('specialty, healthpost_name')
            .eq('user_id', userId)
            .maybeSingle(),
      ]);

      final profileMap = profileResults[0] as Map<String, dynamic>?;
      final doctorMap = profileResults[1] as Map<String, dynamic>?;

      _doctorName = profileMap?['full_name'] ?? 'Doctor';
      _avatarUrl = profileMap?['avatar_url'] as String?;
      _specialty = doctorMap?['specialty'] ?? '';
      _healthpostName = doctorMap?['healthpost_name'] ?? '';

      // ── Step 2: Appointments (table may not exist yet) ───────────────────
      List<dynamic> apptList = [];
      List<dynamic> monthlyList = [];

      try {
        final today = DateTime.now();
        final todayStart = DateTime(
          today.year,
          today.month,
          today.day,
        ).toIso8601String();
        final todayEnd = DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
          59,
        ).toIso8601String();
        final monthStart = DateTime(
          today.year,
          today.month,
          1,
        ).toIso8601String();

        final apptResults = await Future.wait([
          supabase
              .from('appointments')
              .select(
                'id, reason, status, scheduled_at, '
                'patients(user_profiles(full_name))',
              )
              .eq('doctor_id', userId)
              .gte('scheduled_at', todayStart)
              .lte('scheduled_at', todayEnd)
              .order('scheduled_at', ascending: true)
              .limit(10),
          supabase
              .from('appointments')
              .select('id, status')
              .eq('doctor_id', userId)
              .gte(
                'scheduled_at',
                DateTime(today.year, today.month, 1).toIso8601String(),
              ),
        ]);

        apptList = apptResults[0] as List<dynamic>;
        monthlyList = apptResults[1] as List<dynamic>;
      } on PostgrestException catch (pgErr) {
        // PGRST205 = table not in schema cache (table doesn't exist yet).
        // Any other appointments-related error → swallow and show zeros.
        // The doctor's name/info still loads correctly.
        debugPrint(
          'appointments fetch skipped: ${pgErr.code} ${pgErr.message}',
        );
      } catch (_) {
        // Any other error on appointments → show zeros, not a crash screen
        debugPrint('appointments fetch skipped (unknown error)');
      }

      // ── Parse & compute 
      _appointments = apptList
          .map((e) => AppointmentItem.fromMap(e as Map<String, dynamic>))
          .toList();

      _stats = HomeStats(
        todayPatients: _appointments.length,
        pending: _appointments.where((a) => a.status == 'pending').length,
        completed: _appointments.where((a) => a.status == 'completed').length,
        totalThisMonth: monthlyList.length,
      );

      _recentActivity = monthlyList
          .where(
            (e) => e['status'] == 'completed' || e['status'] == 'confirmed',
          )
          .take(5)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      setState(() => _loading = false);
      _animController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return p.isNotEmpty && p[0].isNotEmpty ? p[0][0].toUpperCase() : 'D';
  }

  String _todayLabel() {
    final d = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),

      body: _loading
          ? const HomeShimmer()
          : _error != null
          ? _buildErrorState()
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                color: AppConstants.primaryColor,
                onRefresh: _fetchHomeData,
                child: _buildBody(),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.primaryColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
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
        Obx(() {
          final ct = connectivityController.connectionType.value;
          if (ct == ConnectivityResult.none) {
            return ConnectivityIndicator(icon: Icons.signal_wifi_off);
          } else if (ct == ConnectivityResult.wifi) {
            return ConnectivityIndicator(icon: Icons.wifi);
          } else if (ct == ConnectivityResult.mobile) {
            return ConnectivityIndicator(icon: Icons.signal_cellular_4_bar);
          }
          return const SizedBox.shrink();
        }),
        IconButton(onPressed: () {}, icon: LanguageToggleButton()),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroHeader(
            doctorName: _doctorName,
            specialty: _specialty,
            healthpostName: _healthpostName,
            avatarUrl: _avatarUrl,
            initials: _initials(_doctorName),
            greeting: _greeting(),
            todayLabel: _todayLabel(),
          ),
          const SizedBox(height: 20),
          StatsGrid(stats: _stats),
          const SizedBox(height: 20),
          _SectionHeader(
            title: "Today's appointments",
            actionLabel: 'See all',
            onAction: () {},
          ),
          const SizedBox(height: 10),
          _appointments.isEmpty
              ? const _EmptyAppointments()
              : AppointmentsList(appointments: _appointments),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Quick actions',
            actionLabel: '',
            onAction: null,
          ),
          const SizedBox(height: 10),
          const _QuickActions(),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Recent activity',
            actionLabel: 'View all',
            onAction: () {},
          ),
          const SizedBox(height: 10),
          _recentActivity.isEmpty
              ? const _EmptyActivity()
              : _RecentActivityList(activity: _recentActivity),
          const SizedBox(height: 100), // FAB padding
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load home',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchHomeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}









class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          if (actionLabel.isNotEmpty)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
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




class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No appointments today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your schedule is clear for today',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.person_add_outlined,
        label: 'New patient',
        color: AppConstants.primaryColor,
        bg: const Color(0xFFE8F4FD),
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.calendar_month_outlined,
        label: 'Schedule',
        color: const Color(0xFF8E44AD),
        bg: const Color(0xFFF5EEF8),
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.description_outlined,
        label: 'Prescription',
        color: const Color(0xFF27AE60),
        bg: const Color(0xFFEAF7EF),
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        color: const Color(0xFFF39C12),
        bg: const Color(0xFFFFF8E8),
        onTap: () {},
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions
            .map(
              (a) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: a,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT ACTIVITY
// ─────────────────────────────────────────────────────────────────────────────
class _RecentActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  const _RecentActivityList({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: List.generate(activity.length, (i) {
            final isLast = i == activity.length - 1;
            final item = activity[i];
            final status = item['status'] ?? 'pending';
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: status == 'completed'
                              ? const Color(0xFFEAF7EF)
                              : const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          status == 'completed'
                              ? Icons.check_circle_outline_rounded
                              : Icons.event_available_outlined,
                          size: 18,
                          color: status == 'completed'
                              ? const Color(0xFF27AE60)
                              : AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Appointment ${status}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'completed'
                              ? const Color(0xFFEAF7EF)
                              : const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: status == 'completed'
                                ? const Color(0xFF27AE60)
                                : AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 60,
                    color: Colors.grey.shade100,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'No recent activity',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}


