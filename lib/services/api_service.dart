import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8001/api'; // Chrome
    } else {
      return 'http://10.0.2.2:8001/api'; // Android emulator
    }
  }

  static Dio? _dio;

  static Dio get dio {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final session = Supabase.instance.client.auth.currentSession;
            debugPrint('Session exists: ${session != null}');
            if (session != null) {
              options.headers['Authorization'] = 'Bearer ${session.accessToken}';
            } else {
              debugPrint('No Supabase session found; request will be unauthenticated.');
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
                  e.requestOptions.headers['Authorization'] = 'Bearer ${newSession.accessToken}';
                  e.requestOptions.extra['retried'] = true;
                  final retry = await _dio!.fetch(e.requestOptions);
                  return handler.resolve(retry);
                }
              } catch (_) {}
            }
            return handler.next(e);
          },
        ),
      );
    }
    return _dio!;
  }



  static Future<Map<String, dynamic>> bookAppointment({
    required int doctorTableId,
    required String consultationType,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? patientNotes,
  }) async {
    try {
      final res = await dio.post(
        '/appointments/',
        data: {
          'doctor_id': doctorTableId,
          'consultation_type': consultationType,
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'duration_minutes': durationMinutes,
          'patient_notes': patientNotes,
        },
      );
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
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await dio.post(
        '/appointments/check-slots',
        data: {'doctor_id': doctorTableId, 'date': dateStr},
      );
      final data = res.data as Map<String, dynamic>;
      return List<String>.from(data['booked_slots'] ?? []);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getMyAppointments() async {
    try {
      final res = await dio.get('/appointments/');
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final res = await dio.get('/appointments/upcoming/list');
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getAppointmentsByStatus(String status) async {
    try {
      final res = await dio.get('/appointments/filter/$status');
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getAppointment(String appointmentId) async {
    try {
      final res = await dio.get('/appointments/$appointmentId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/cancel');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }



  /// Confirm a pending appointment (doctor only)
  static Future<Map<String, dynamic>> confirmAppointment(String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/confirm');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }



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
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getMonthlyAppointments({
    int? year,
    int? month,
  }) async {
    try {
      final now = DateTime.now();
      final query = {
        'year': (year ?? now.year).toString(),
        'month': (month ?? now.month).toString(),
      };
      final res = await dio.get('/appointments/doctor/monthly', queryParameters: query);
      return List<Map<String, dynamic>>.from(res.data);
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
    final params = <String, dynamic>{'specialty': specialty};
    if (province != null && province.isNotEmpty) params['province'] = province;
    if (district != null) params['district'] = district;
    if (municipality != null && municipality.isNotEmpty) params['municipality'] = municipality;

    final res = await dio.get('/doctors/', queryParameters: params);
    return List<Map<String, dynamic>>.from(res.data);
  }

  /// Mark an appointment as completed (doctor only)
  static Future<Map<String, dynamic>> completeAppointment(String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/complete');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark an appointment as no‑show (doctor only)
  static Future<Map<String, dynamic>> noShowAppointment(String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/no-show');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
// Add inside ApiService class:
  static Future<Map<String, dynamic>> initiateCall({
    required String calleeId,
    required String appointmentId,
    required String callType, // 'audio' | 'video'
  }) async {
    try {
      final res = await dio.post(
        '/calls/initiate',
        data: {
          'callee_id': calleeId,
          'appointment_id': appointmentId,
          'call_type': callType,
        },
      );
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
      case 400:
        return 'अनुरोध गलत छ: $detail';
      case 401:
        return 'लग इन आवश्यक छ।';
      case 403:
        return 'यो काम गर्न अनुमति छैन।';
      case 404:
        return 'डाटा भेटिएन।';
      case 409:
        return 'यो समय अहिले बुक भयो। अर्को छान्नुहोस्।';
      case 500:
        return 'सर्भर त्रुटि। पछि पुनः प्रयास गर्नुहोस्।';
      default:
        return detail.toString();
    }
  }
}