

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
final healthpostsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ApiService.getHealthposts();
    });
final createReferralProvider =
    Provider<Future<Map<String, dynamic>> Function(Map<String, dynamic>)>(
      (ref) =>
          (payload) => ApiService.createReferral(payload),
    );

final patientReferralsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, patientId) async {
      return ApiService.getPatientReferrals(patientId);
    });

final facilitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ApiService.getFacilities();
    });
