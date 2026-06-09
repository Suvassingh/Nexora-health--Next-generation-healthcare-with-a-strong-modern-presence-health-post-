import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AppointmentReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Call this once after app starts (e.g., in main after initializing notifications)
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  // Cancel all pending reminders and reschedule for the current user
  // static Future<void> rescheduleAllReminders() async {
  //   await _cancelAllPending();
  //   final userId = Supabase.instance.client.auth.currentUser?.id;
  //   if (userId == null) return;
  //
  //   // Fetch confirmed appointments that are in the future
  //   final now = DateTime.now();
  //   final response = await Supabase.instance.client
  //       .from('appointments')
  //       .select('id, scheduled_at, patient_id, doctor_id, consultation_type')
  //       .eq('status', 'confirmed')
  //       .gt('scheduled_at', now.toIso8601String())
  //       .or('patient_id.eq.$userId,doctor_id.eq.$userId');
  //
  //   final appointments = List<Map<String, dynamic>>.from(response);
  //   for (final apt in appointments) {
  //     await _scheduleReminder(apt);
  //   }
  // }

  static Future<void> rescheduleAllReminders() async {
    await _cancelAllPending();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Get user role
    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    final role = profile?['role'] as String?;

    // 2. Build query based on role
    var query = Supabase.instance.client
        .from('appointments')
        .select('id, scheduled_at, patient_id, doctor_id, consultation_type')
        .eq('status', 'confirmed')
        .gt('scheduled_at', DateTime.now().toIso8601String());

    if (role == 'patient') {
      query = query.eq('patient_id', userId);
    } else if (role == 'doctor') {
      final doctorRecord = await Supabase.instance.client
          .from('doctors')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      final doctorIdInt = doctorRecord?['id'] as int?;
      if (doctorIdInt == null) return;
      query = query.eq('doctor_id', doctorIdInt);
    } else {
      return;
    }

    final response = await query;
    final appointments = List<Map<String, dynamic>>.from(response);
    for (final apt in appointments) {
      await _scheduleReminder(apt);
    }
  }

  static Future<void> _cancelAllPending() async {
    await _notifications.cancelAll();
  }

  static Future<void> _scheduleReminder(
    Map<String, dynamic> appointment,
  ) async {
    final scheduledAt = DateTime.parse(appointment['scheduled_at']);
    final reminderTime = scheduledAt.subtract(const Duration(minutes: 30));
    final now = DateTime.now();

    if (reminderTime.isBefore(now)) return; // already passed

    final delay = reminderTime.difference(now);
    final appointmentId = appointment['id'] as String;

    // Build a meaningful title/body based on user role
    final userId = Supabase.instance.client.auth.currentUser?.id;
    bool isPatient = appointment['patient_id'] == userId;
    String doctorName = await _fetchDoctorName(appointment['doctor_id']);
    String title = isPatient
        ? 'Appointment reminder'
        : 'Upcoming appointment with patient';
    String body = isPatient
        ? 'You have an appointment with Dr. $doctorName in 30 minutes.'
        : 'You have an appointment with a patient in 30 minutes.';

    const androidDetails = AndroidNotificationDetails(
      'appointment_reminder',
      'Appointment reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule exactly once at the computed time
    await _notifications.zonedSchedule(
      appointmentId.hashCode,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(delay),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<String> _fetchDoctorName(dynamic doctorId) async {
    try {
      // doctor_id can be integer (table id) or UUID? In your schema it's integer.
      final res = await Supabase.instance.client
          .from('doctors')
          .select('user_id')
          .eq('id', doctorId)
          .maybeSingle();
      final userId = res?['user_id'];
      if (userId != null) {
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select('full_name')
            .eq('id', userId)
            .maybeSingle();
        return profile?['full_name'] ?? 'Doctor';
      }
      return 'Doctor';
    } catch (_) {
      return 'Doctor';
    }
  }
}
