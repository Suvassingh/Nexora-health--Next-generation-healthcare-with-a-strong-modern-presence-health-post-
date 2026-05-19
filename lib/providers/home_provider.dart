import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthpost_app/services/api_service.dart';
import 'package:healthpost_app/home_page.dart';

class HomeData {
  final String doctorName;
  final String specialty;
  final String healthpostName;
  final String? avatarUrl;
  final HomeStats stats;
  final List<AppointmentItem> appointments;
  final List<int> weeklyCount;

  final List<Map<String, dynamic>> recentActivity;

  const HomeData({
    required this.doctorName,
    required this.specialty,
    required this.healthpostName,
    required this.avatarUrl,
    required this.stats,
    required this.appointments,
    required this.weeklyCount,
    required this.recentActivity,
  });
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final doctorProfile = await ApiService.getDoctorProfile();
  final todayAppts = await ApiService.getTodayAppointments();
  final monthlyAppts = await ApiService.getMonthlyAppointments();
  final stats = await ApiService.getDoctorStats();

  final appointments =
  todayAppts.map((json) => AppointmentItem.fromApi(json)).toList();

  final homeStats = HomeStats(
    todayPatients: stats['today_count'] ?? appointments.length,
    pending:
    stats['pending_count'] ??
        appointments.where((a) => a.status == 'pending').length,
    completed:
    stats['completed_count'] ??
        appointments.where((a) => a.status == 'completed').length,
    totalThisMonth: stats['total_this_month'] ?? monthlyAppts.length,
  );

  final recentActivity = monthlyAppts
      .where((e) => e['status'] == 'completed' || e['status'] == 'confirmed')
      .take(5)
      .toList();
  List<int> weeklyCount = List.filled(7, 0);
  for (var appt in monthlyAppts) {
    if (appt['scheduled_at'] != null) {
      final date = DateTime.parse(appt['scheduled_at']).toLocal();
      final weekdayIndex = date.weekday - 1; // Monday = 0
      weeklyCount[weekdayIndex]++;
    }
  }
  return HomeData(
    doctorName: doctorProfile['full_name'] ?? 'Doctor',
    specialty: doctorProfile['specialty'] ?? '',
    healthpostName: doctorProfile['healthpost_name'] ?? '',
    avatarUrl: doctorProfile['avatar_url'] as String?,
    stats: homeStats,
    appointments: appointments,
    weeklyCount: weeklyCount,
    recentActivity: recentActivity,
  );
});