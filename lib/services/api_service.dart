
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
abstract class NotifType {
  static const appointmentConfirmed = 'appointment_confirmed';
  static const appointmentCancelled = 'appointment_cancelled';
  static const appointmentReminder  = 'appointment_reminder';
  static const callIncoming         = 'call_incoming';
  static const chatMessage          = 'chat_message';
  static const completed            = 'completed';

  static const newAppointment = 'new_appointment';
  static const noShow         = 'no_show';
}
class ApiService {
  //  BASE URL 

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8001/api';
    return 'http://10.0.2.2:8001/api'; // Android emulator → host loopback
  }

  //  DIO SINGLETON 

  static Dio? _dio;

  static Dio get dio {
    if (_dio != null) return _dio!;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        } else {
          debugPrint('[ApiService] No Supabase session — request unauthenticated');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 &&
            e.requestOptions.extra['retried'] != true) {
          try {
            await Supabase.instance.client.auth.refreshSession();
            final newSession = Supabase.instance.client.auth.currentSession;
            if (newSession != null) {
              e.requestOptions.headers['Authorization'] =
              'Bearer ${newSession.accessToken}';
              e.requestOptions.extra['retried'] = true;
              final retry = await _dio!.fetch(e.requestOptions);
              return handler.resolve(retry);
            }
          } catch (_) {}
        }
        return handler.next(e);
      },
    ));

    return _dio!;
  }

  // Reset singleton (call after logout)
  static void resetDio() => _dio = null;
  static Future<void> sendNotification({
    required String recipientUserId,
    required String userType, // 'patient' | 'doctor'
    required String title,
    required String body,
    required String type,
    Map<String, String> data = const {},
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.functions.invoke(
      'send-notification',
      body: {
        'recipientUserId': recipientUserId,
        'userType': userType,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
      },
    );
  }
  //  TURN 

  static Future<Map<String, dynamic>> fetchTurnCredentials() async {
    try {
      final res = await dio.get('/turn-credentials');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //  CALLS 

  static Future<Map<String, dynamic>> initiateCall({
    required String calleeId,
    required String appointmentId,
    required String callType, // 'audio' | 'video'
  }) async {
    try {
      final res = await dio.post('/calls/initiate', data: {
        'callee_id': calleeId,
        'appointment_id': appointmentId,
        'call_type': callType,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> updateCallStatus({
    required String callId,
    required String status, // 'accepted' | 'declined' | 'ended' | 'missed'
  }) async {
    try {
      await dio.patch('/calls/$callId/status', data: {'status': status});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getCallHistory() async {
    try {
      final res = await dio.get('/calls/history');
      return List<Map<String, dynamic>>.from(res.data as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //  APPOINTMENTS 

  static Future<Map<String, dynamic>> bookAppointment({
    required int doctorTableId,
    required String consultationType,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? patientNotes,
  }) async {
    try {
      final res = await dio.post('/appointments/', data: {
        'doctor_id': doctorTableId,
        'consultation_type': consultationType,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'duration_minutes': durationMinutes,
        'patient_notes': patientNotes,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<String>> checkSlotAvailability({
    required int doctorTableId,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final res = await dio.post('/appointments/check-slots',
          data: {'doctor_id': doctorTableId, 'date': dateStr});
      return List<String>.from((res.data as Map)['booked_slots'] ?? []);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getMyAppointments() async {
    try {
      final res = await dio.get('/appointments/');
      return List<Map<String, dynamic>>.from(res.data as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final res = await dio.get('/appointments/upcoming/list');
      return List<Map<String, dynamic>>.from(res.data as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getAppointmentsByStatus(
      String status) async {
    try {
      final res = await dio.get('/appointments/filter/$status');
      return List<Map<String, dynamic>>.from(res.data as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getAppointment(
      String appointmentId) async {
    try {
      final res = await dio.get('/appointments/$appointmentId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> cancelAppointment(
      String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/cancel');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> confirmAppointment(
      String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/confirm');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> completeAppointment(
      String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/complete');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> noShowAppointment(
      String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/no-show');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //  DOCTORS 

  static Future<Map<String, dynamic>> getDoctorProfile() async {
    try {
      final res = await dio.get('/doctors/me');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayAppointments() async {
    try {
      final res = await dio.get('/appointments/doctor/today');
      return List<Map<String, dynamic>>.from(res.data as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getMonthlyAppointments({
    int? year, int? month,
  }) async {
    try {
      final now = DateTime.now();
      final res = await dio.get('/appointments/doctor/monthly', queryParameters: {
        'year': (year ?? now.year).toString(),
        'month': (month ?? now.month).toString(),
      });
      return List<Map<String, dynamic>>.from(res.data as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getDoctorStats() async {
    try {
      final res = await dio.get('/doctors/stats');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchDoctors({
    required String specialty,
    String? province,
    String? district,
    String? municipality,
  }) async {
    try {
      final params = <String, dynamic>{'specialty': specialty};
      if (province != null && province.isNotEmpty) params['province'] = province;
      if (district != null) params['district'] = district;
      if (municipality != null && municipality.isNotEmpty)
        params['municipality'] = municipality;
      final res = await dio.get('/doctors/', queryParameters: params);
      return List<Map<String, dynamic>>.from(res.data as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
//  HEALTH RECORDS 

  static Future<Map<String, dynamic>> getPatientHealthSummary(
    String patientId,
  ) async {
    try {
      final res = await dio.get('/health-records/summary/$patientId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  //  ERROR HANDLER 

  static String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'सर्भरसँग जडान गर्न समय लाग्यो। पुनः प्रयास गर्नुहोस्।';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'इन्टरनेट जडान छैन वा सर्भर बन्द छ।';
    }
    final statusCode = e.response?.statusCode;
    final detail = e.response?.data is Map
        ? e.response?.data['detail'] ?? 'अज्ञात त्रुटि'
        : 'अज्ञात त्रुटि';
    switch (statusCode) {
      case 400: return 'अनुरोध गलत छ: $detail';
      case 401: return 'लग इन आवश्यक छ।';
      case 403: return 'यो काम गर्न अनुमति छैन।';
      case 404: return 'डाटा भेटिएन।';
      case 409: return 'यो समय अहिले बुक भयो। अर्को छान्नुहोस्।';
      case 500: return 'सर्भर त्रुटि। पछि पुनः प्रयास गर्नुहोस्।';
      default:  return detail.toString();
    }
  }
}