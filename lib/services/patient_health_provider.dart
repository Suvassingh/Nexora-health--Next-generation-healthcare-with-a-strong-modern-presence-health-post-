
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthpost_app/services/api_service.dart';

final patientHealthSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, patientId) async {
      if (patientId.isEmpty) {
        throw Exception('patientId must not be empty');
      }

      final res = await ApiService.dio.get(
        '/health-records/summary/$patientId',
      );
      return Map<String, dynamic>.from(res.data as Map);
    });

final doctorPatientsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final res = await ApiService.dio.get('/appointments/doctor/patients');
  return List<Map<String, dynamic>>.from(res.data as List);
});
