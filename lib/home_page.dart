
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/appointment_screen.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/widgets/home_appointment.dart';
import 'package:healthpost_app/widgets/home_hero_header.dart';
import 'package:healthpost_app/widgets/home_simmer.dart';
import 'package:healthpost_app/widgets/home_stat.dart';
import 'package:healthpost_app/widgets/notice_stripe.dart';
import 'package:healthpost_app/widgets/recent_patient_row.dart';
import 'package:healthpost_app/widgets/weekly_chart.dart';
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
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : '?';
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
  final ConnectivityController connectivityController = Get.put(
    ConnectivityController(),
  );


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



  String _greeting(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l.goodMorning;
    if (hour < 17) return l.goodAfternoon;
    return l.goodEvening;
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : 'D';
  }

  String _todayLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = DateTime.now();
    final days = [
      l.monday,
      l.tuesday,
      l.wednesday,
      l.thursday,
      l.friday,
      l.saturday,
      l.sunday,
    ];
    final months = [
      l.jan,
      l.feb,
      l.mar,
      l.apr,
      l.mayShort,
      l.jun,
      l.jul,
      l.aug,
      l.sep,
      l.oct,
      l.nov,
      l.dec,
    ];
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
                const SizedBox(width: 4),

        const LanguageToggleButton(),
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
            greeting: _greeting(context),
            todayLabel: _todayLabel(context),
          ),
          SizedBox(height: 12),
          NoticeStrip(notices: [],),

          const SizedBox(height: 20),

          StatsGrid(stats: data.stats),

          const SizedBox(
            height: 20,
          ), 
          if (data.appointments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.nextPatient,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            data.appointments.first.patientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            data.appointments.first.time,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(AppLocalizations.of(context)!.start,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        _SectionHeader(
            title: AppLocalizations.of(context)!.todaysAppointments,
            actionLabel: AppLocalizations.of(context)!.seeAll,
            onAction: () {
              Get.to(() => DoctorAppointmentsScreen());
            },
          ),

          const SizedBox(height: 10),
          RecentPatientsRow(appointments:data.appointments,),
          const SizedBox(height: 10),

          data.appointments.isEmpty
              ? const _EmptyAppointments()
              : AppointmentsList(appointments: data.appointments),

          const SizedBox(height: 20),
WeeklyChart(dailyCounts:data.weeklyCount ),
          
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

Text(AppLocalizations.of(context)!.couldNotLoadHome),

          const SizedBox(height: 8),

          Text(error),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              ref.invalidate(homeDataProvider);
            },
            child: Text(AppLocalizations.of(context)!.retry),

          ),
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
            Text(AppLocalizations.of(context)!.noAppointmentsToday,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.scheduleIsClear,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}


