
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  static String baseUrl = 'http://45.115.217.244/api';

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
  static Dio? _supabaseFunctionsDio;

  static Dio get supabaseFunctionsDio {
    if (_supabaseFunctionsDio != null) return _supabaseFunctionsDio!;

    final supabaseAnonKey = dotenv.env['supabase_anonKey'];
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('Missing supabase_anonKey in .env file');
    }

    _supabaseFunctionsDio = Dio(
      BaseOptions(
        baseUrl: 'https://clmlpgtxonfdnhjgdtxm.supabase.co/functions/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      ),
    );
    return _supabaseFunctionsDio!;
  }
  static void resetDio() => _dio = null;

  static Future<void> _sendPushNotification({
    required String recipientUserId,
    required String userType,
    required String title,
    required String body,
    required String type,
    Map<String, String>? data,
  }) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'send-push-notification',
        body: {
          'recipientUserId': recipientUserId,
          'userType': userType,
          'title': title,
          'body': body,
          'type': type,
          'data': data ?? {},
        },
      );
    } catch (e) {
      debugPrint('Notification send failed: $e');
    }
  }

  static Future<void> sendNotification({
    required String recipientUserId,
    required String userType,
    required String title,
    required String body,
    required String type,
    Map<String, String> data = const {},
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.functions.invoke(
      'send-push-notification',
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

  static Future<Map<String, dynamic>> fetchTurnCredentials() async {
    try {
      final res = await dio.get('/turn-credentials');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> initiateCall({
    required String calleeId,
    required String appointmentId,
    required String callType,
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
    required String status,
  }) async {
    try {
      await dio.patch('/calls/$callId/status', data: {'status': status});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // static Future<List<Map<String, dynamic>>> getCallHistory() async {
  //   try {
  //     final res = await dio.get('/calls/history');
  //     return List<Map<String, dynamic>>.from(res.data as List);
  //   } on DioException catch (e) {
  //     throw _handleError(e);
  //   }
  // }


  static Future<List<Map<String, dynamic>>> getCallHistory() async {
  final res = await dio.get('/calls/history');
  final calls = List<Map<String, dynamic>>.from(res.data);
  final supabase = Supabase.instance.client;

  // Enrich each call with the other party's name
  final enriched = await Future.wait(calls.map((call) async {
    final isCaller = call['caller_id'] == supabase.auth.currentUser?.id;
    final otherId = isCaller ? call['callee_id'] : call['caller_id'];
    final profile = await supabase
        .from('user_profiles')
        .select('full_name')
        .eq('id', otherId)
        .maybeSingle();
    call['caller_name'] = profile?['full_name'] ?? 'Unknown';
    call['callee_name'] = call['caller_name']; // reuse for simplicity
    return call;
  }));
  return enriched;
}

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
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  static Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/cancel');
      final appointment = res.data as Map<String, dynamic>;
      debugPrint('cancelAppointment response: $appointment');

      dynamic patientIdRaw = appointment['patient_id'];
      debugPrint(' patient_id raw: $patientIdRaw (type: ${patientIdRaw.runtimeType})');

      String? patientUserId;
      if (patientIdRaw is String && patientIdRaw.contains('-')) {
        patientUserId = patientIdRaw;
      } else if (patientIdRaw is int) {
        final supabase = Supabase.instance.client;
        final patientRecord = await supabase
            .from('patients')
            .select('user_id')
            .eq('id', patientIdRaw)
            .maybeSingle();
        patientUserId = patientRecord?['user_id'] as String?;
      }

      if (patientUserId == null) {
        debugPrint('❌ Could not resolve patient user ID');
      } else {
        final doctorName = appointment['doctor_name'] ?? 'Doctor';
        await _sendPushNotification(
          recipientUserId: patientUserId,
          userType: 'patient',
          title: 'Appointment Cancelled',
          body: 'Your appointment with Dr. $doctorName has been cancelled.',
          type: NotifType.appointmentCancelled,
          data: {'appointment_id': appointmentId},
        );
      }
      return appointment;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> confirmAppointment(String appointmentId) async {
    try {
      final res = await dio.patch('/appointments/$appointmentId/confirm');
      final appointment = res.data as Map<String, dynamic>;
      debugPrint('confirmAppointment response: $appointment');

      dynamic patientIdRaw = appointment['patient_id'];
      debugPrint(' patient_id raw: $patientIdRaw (type: ${patientIdRaw.runtimeType})');

      String? patientUserId;
      if (patientIdRaw is String && patientIdRaw.contains('-')) {
        patientUserId = patientIdRaw;
      } else if (patientIdRaw is int) {
        final supabase = Supabase.instance.client;
        final patientRecord = await supabase
            .from('patients')
            .select('user_id')
            .eq('id', patientIdRaw)
            .maybeSingle();
        patientUserId = patientRecord?['user_id'] as String?;
      }

      if (patientUserId == null) {
        debugPrint(' Could not resolve patient user ID');
      } else {
        final doctorName = appointment['doctor_name'] ?? 'Doctor';
        await _sendPushNotification(
          recipientUserId: patientUserId,
          userType: 'patient',
          title: 'Appointment Confirmed',
          body: 'Your appointment with Dr. $doctorName has been confirmed.',
          type: NotifType.appointmentConfirmed,
          data: {'appointment_id': appointmentId},
        );
      }
      return appointment;
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
    int? year,
    int? month,
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

  static Future<Map<String, dynamic>> getPatientHealthSummary(
      String patientId) async {
    try {
      final res = await dio.get('/health-records/summary/$patientId');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<Map<String, dynamic>>> getHealthposts() async {
    final res = await dio.get('/healthposts/');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  static Future<List<Map<String, dynamic>>> getFacilities() async {
    final res = await dio.get('/facilities/');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  static Future<Map<String, dynamic>> createReferral(
      Map<String, dynamic> payload) async {
    final res = await dio.post('/referrals/', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  static Future<List<Map<String, dynamic>>> getPatientReferrals(
      String patientId) async {
    final res = await dio.get('/referrals/',
        queryParameters: {'patient_id': patientId});
    return List<Map<String, dynamic>>.from(res.data as List);
  }


  static Future<Map<String, String>> initiateLiveKitCall({
    required String callerId,
    required String calleeId,
    required String appointmentId,
    required String callType,
    required String callerName,
  }) async {
    try {
      debugPrint(' Calling Supabase Edge Function /initiate-call');
      debugPrint('   callerId: $callerId');
      debugPrint('   calleeId: $calleeId');

      final response = await supabaseFunctionsDio.post(
        '/initiate-call',
        data: {
          'callerId': callerId,
          'calleeId': calleeId,
          'appointmentId': appointmentId,
          'callType': callType,
          'callerName': callerName,
        },
      );

      debugPrint(' initiate-call response: ${response.data}');
      final data = response.data as Map<String, dynamic>;
      return {
        'callerToken': data['callerToken'] as String,
        'roomName': data['roomName'] as String,
      };
    } on DioException catch (e) {
      debugPrint(' initiate-call failed: ${e.response?.statusCode} ${e.response?.data}');
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