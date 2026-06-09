import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthpost_app/models/doctor_appointment.dart';
import 'package:healthpost_app/services/api_service.dart';

class AppointmentsData {
  final List<DAppt> pending;
  final List<DAppt> today;
  final List<DAppt> upcoming;
  final List<DAppt> completed;
  final List<DAppt> cancelled;

  const AppointmentsData({
    this.pending = const [],
    this.today = const [],
    this.upcoming = const [],
    this.completed = const [],
    this.cancelled = const [],
  });
}

final appointmentsProvider =
AsyncNotifierProvider<AppointmentsNotifier, AppointmentsData>(
  AppointmentsNotifier.new,
);

class AppointmentsNotifier extends AsyncNotifier<AppointmentsData> {
  @override
  Future<AppointmentsData> build() async {
    return _fetch();
  }

//   Future<AppointmentsData> _fetch() async {
//     final rows = await ApiService.getMyAppointments();
//     final all = rows.map((json) => DAppt.fromApi(json)).toList();

// final nowUtc = DateTime.now().toUtc();
//     final todayStartUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
//     final todayEndUtc = todayStartUtc.add(const Duration(days: 1));

//     List<DAppt> pending = all.where((a) => a.status == 'pending').toList()
//       ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

//     // List<DAppt> today = all
//     //     .where((a) =>
//     // a.status == 'confirmed' &&
//     //     a.scheduledAt.isAfter(todayStart) &&
//     //     a.scheduledAt.isBefore(todayEnd))
//     //     .toList()
//     //   ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
//     List<DAppt> today = all
//         .where(
//           (a) =>
//               a.status == 'confirmed' &&
//               a.scheduledAt.isAfter(todayStartUtc) &&
//               a.scheduledAt.isBefore(todayEndUtc),
//         )
//         .toList();

//     List<DAppt> upcoming = all
//         .where(
//           (a) => a.status == 'confirmed' && a.scheduledAt.isAfter(todayEndUtc),
//     )
//         .toList()
//       ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

//     List<DAppt> completed = all.where((a) => a.status == 'completed').toList()
//       ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

//     List<DAppt> cancelled = all
//         .where((a) => a.status == 'cancelled' || a.status == 'no_show')
//         .toList()
//       ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

//     return AppointmentsData(
//       pending: pending,
//       today: today,
//       upcoming: upcoming,
//       completed: completed,
//       cancelled: cancelled,
//     );
//   }


Future<AppointmentsData> _fetch() async {
    final rows = await ApiService.getMyAppointments();
    final all = rows.map((json) => DAppt.fromApi(json)).toList();

    // Use UTC for all date comparisons
    final nowUtc = DateTime.now().toUtc();
    final todayStartUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final todayEndUtc = todayStartUtc.add(const Duration(days: 1));
print('Current UTC date: ${DateTime.now().toUtc()}');
print('Today UTC start: $todayStartUtc');
print('Today UTC end: $todayEndUtc');
    // Pending
    final pending = all.where((a) => a.status == 'pending').toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Today – compare UTC times directly
    final today =
        all
            .where(
              (a) =>
                  a.status == 'confirmed' &&
                  a.scheduledAt.isAfter(todayStartUtc) &&
                  a.scheduledAt.isBefore(todayEndUtc),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Upcoming – after today UTC
    final upcoming =
        all
            .where(
              (a) =>
                  a.status == 'confirmed' && a.scheduledAt.isAfter(todayEndUtc),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Completed & Cancelled
    final completed = all.where((a) => a.status == 'completed').toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    final cancelled =
        all
            .where((a) => a.status == 'cancelled' || a.status == 'no_show')
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    // 🔍 Debug prints – remove after verification
    print('=== TODAY UTC ===');
    print('Start: $todayStartUtc, End: $todayEndUtc');
    print(
      'Confirmed appointments count: ${all.where((a) => a.status == 'confirmed').length}',
    );
    print('Today count: ${today.length}');
    for (var a in today) {
      print('Today appt: ${a.id} at ${a.scheduledAt.toIso8601String()}');
    }

    return AppointmentsData(
      pending: pending,
      today: today,
      upcoming: upcoming,
      completed: completed,
      cancelled: cancelled,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> updateStatus(
      String apptId,
      Future<void> Function(String) apiCall,
      ) async {
    await apiCall(apptId);
    await refresh();
  }
}