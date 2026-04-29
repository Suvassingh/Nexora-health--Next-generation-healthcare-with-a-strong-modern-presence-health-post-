import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/services/api_service.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthpost_app/providers/home_provider.dart';
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
  final String status;
  final String? patientInitials;

  const AppointmentItem({
    required this.id,
    required this.patientName,
    required this.reason,
    required this.time,
    required this.status,
    this.patientInitials,
  });

  factory AppointmentItem.fromApi(Map<String, dynamic> json) {
    final patientName = json['patient_full_name'] ?? 'Unknown';
    return AppointmentItem(
      id: json['id']?.toString() ?? '',
      patientName: patientName,
      reason: json['patient_notes'] ?? 'General Consultation',
      time: _formatTime(json['scheduled_at']),
      status: json['status'] ?? 'pending',
      patientInitials: _initials(patientName),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  static String _formatTime(dynamic iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final minute = d.minute.toString().padLeft(2, '0');
      final ampm = d.hour < 12 ? 'AM' : 'PM';
      return '$hour:$minute $ampm';
    } catch (_) {
      return '';
    }
  }
}

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen>
    with SingleTickerProviderStateMixin {
  final ConnectivityController connectivityController = Get.put(ConnectivityController());

  // // Data fields
  // String _doctorName = '';
  // String _specialty = '';
  // String _healthpostName = '';
  // String? _avatarUrl;
  // HomeStats _stats = const HomeStats();
  // List<AppointmentItem> _appointments = [];
  // List<Map<String, dynamic>> _recentActivity = [];
  //
  // // UI state
  // bool _loading = true;
  // String? _error;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Future<void> _fetchHomeData() async {
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //   });
  //
  //   try {
  //
  //     final doctorProfile = await ApiService.getDoctorProfile();
  //     _specialty = doctorProfile['specialty'] ?? '';
  //     _healthpostName = doctorProfile['healthpost_name'] ?? '';
  //     _doctorName = doctorProfile['full_name'] ?? 'Doctor';
  //     _avatarUrl = doctorProfile['avatar_url'] as String?;
  //
  //
  //     final todayAppts = await ApiService.getTodayAppointments();
  //     _appointments = todayAppts.map((json) => AppointmentItem.fromApi(json)).toList();
  //
  //
  //     final monthlyAppts = await ApiService.getMonthlyAppointments();
  //
  //     final stats = await ApiService.getDoctorStats();
  //     _stats = HomeStats(
  //       todayPatients: stats['today_count'] ?? _appointments.length,
  //       pending: stats['pending_count'] ?? _appointments.where((a) => a.status == 'pending').length,
  //       completed: stats['completed_count'] ?? _appointments.where((a) => a.status == 'completed').length,
  //       totalThisMonth: stats['total_this_month'] ?? monthlyAppts.length,
  //     );
  //     print('DEBUG stats: $stats');
  //
  //     _recentActivity = monthlyAppts
  //         .where((e) => e['status'] == 'completed' || e['status'] == 'confirmed')
  //         .take(5)
  //         .toList();
  //
  //     setState(() => _loading = false);
  //     _animController.forward();
  //   } catch (e) {
  //     setState(() {
  //       _error = e.toString();
  //       _loading = false;
  //     });
  //   }
  // }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'D';
  }

  String _todayLabel() {
    final d = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {

    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: homeAsync.when(
        loading: () => const HomeShimmer(),

        error: (e, _) => _buildErrorState(e.toString()),

        data: (data) {

          if (!_animController.isCompleted) {
            _animController.forward();
          }

          return FadeTransition(
            opacity: _fadeAnim,
            child: RefreshIndicator(
              color: AppConstants.primaryColor,

              onRefresh: () async {
                ref.invalidate(homeDataProvider);
              },

              child: _buildBody(data),
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
      automaticallyImplyLeading: false,
      title: const Row(
        children: [
          Image(image: AssetImage('assets/images/gov_logo.webp'), width: 36, height: 36),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppConstants.nepalSarkar, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(AppConstants.govtOfNepal, style: TextStyle(fontSize: 9, color: Colors.white70)),
            ],
          ),
        ],
      ),
      actions: [
        Obx(() {
          final ct = connectivityController.connectionType.value;
          if (ct == ConnectivityResult.none) return const ConnectivityIndicator(icon: Icons.signal_wifi_off);
          if (ct == ConnectivityResult.wifi) return const ConnectivityIndicator(icon: Icons.wifi);
          if (ct == ConnectivityResult.mobile) return const ConnectivityIndicator(icon: Icons.signal_cellular_4_bar);
          return const SizedBox.shrink();
        }),
        IconButton(onPressed: () {}, icon: const LanguageToggleButton()),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(HomeData data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          HeroHeader(
            doctorName: data.doctorName,
            specialty: data.specialty,
            healthpostName: data.healthpostName,
            avatarUrl: data.avatarUrl,
            initials: _initials(data.doctorName),
            greeting: _greeting(),
            todayLabel: _todayLabel(),
          ),

          const SizedBox(height: 20),

          StatsGrid(stats: data.stats),

          const SizedBox(height: 20),

          _SectionHeader(
            title: "Today's appointments",
            actionLabel: 'See all',
            onAction: () {},
          ),

          const SizedBox(height: 10),

          data.appointments.isEmpty
              ? const _EmptyAppointments()
              : AppointmentsList(appointments: data.appointments),

          const SizedBox(height: 20),

          _SectionHeader(
            title: 'Quick actions',
            actionLabel: '',
            onAction: null,
          ),

          const SizedBox(height: 10),

          const _QuickActions(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Icon(Icons.cloud_off_rounded, size: 64),

          const SizedBox(height: 16),

          const Text("Could not load home"),

          const SizedBox(height: 8),

          Text(error),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              ref.invalidate(homeDataProvider);
            },
            child: const Text("Retry"),
          )
        ],
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





