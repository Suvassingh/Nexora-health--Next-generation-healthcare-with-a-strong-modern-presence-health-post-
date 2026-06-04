import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthpost_app/services/api_service.dart';


final patientHealthSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, patientId) async {
      if (patientId.isEmpty) throw Exception('patientId must not be empty');
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

class SaveState {
  final bool isSaving;
  final String? error;
  const SaveState({this.isSaving = false, this.error});
  SaveState copyWith({bool? isSaving, String? error}) =>
      SaveState(isSaving: isSaving ?? this.isSaving, error: error);
}

class SaveNotifier extends Notifier<SaveState> {
  @override
  SaveState build() => const SaveState();

   Future<bool> run(
    Future<void> Function() call, {
    required String patientId,
  }) async {
    state = const SaveState(isSaving: true);
    try {
      await call();
       ref.invalidate(patientHealthSummaryProvider(patientId));
      state = const SaveState();
      return true;
    } catch (e) {
      state = SaveState(error: e.toString());
      return false;
    }
  }

  void clearError() => state = const SaveState();
}

final saveNotifierProvider = NotifierProvider<SaveNotifier, SaveState>(
  SaveNotifier.new,
);

//  VITALS 

final updateVitalsProvider = Provider((_) => _updateVitals);

Future<void> _updateVitals(String vitalsId, Map<String, dynamic> data) =>
    ApiService.dio.patch('/health-records/vitals/$vitalsId', data: data);

//  ALLERGIES 

final addAllergyProvider = Provider((_) => _addAllergy);
Future<void> _addAllergy(String patientId, Map<String, dynamic> data) =>
    ApiService.dio.post('/health-records/$patientId/allergies', data: data);

final editAllergyProvider = Provider((_) => _editAllergy);
Future<void> _editAllergy(
  String patientId,
  String allergyId,
  Map<String, dynamic> data,
) => ApiService.dio.patch(
  '/health-records/$patientId/allergies/$allergyId/edit',
  data: data,
);

final toggleAllergyProvider = Provider((_) => _toggleAllergy);
Future<void> _toggleAllergy(
  String patientId,
  String allergyId,
  bool isActive,
) => ApiService.dio.patch(
  '/health-records/$patientId/allergies/$allergyId',
  queryParameters: {'is_active': isActive},
);

//  CONDITIONS 

final addConditionProvider = Provider((_) => _addCondition);
Future<void> _addCondition(String patientId, Map<String, dynamic> data) =>
    ApiService.dio.post('/health-records/$patientId/conditions', data: data);

final editConditionProvider = Provider((_) => _editCondition);
Future<void> _editCondition(
  String patientId,
  String conditionId,
  Map<String, dynamic> data,
) => ApiService.dio.patch(
  '/health-records/$patientId/conditions/$conditionId/edit',
  data: data,
);

//  MEDICAL HISTORY 

final addHistoryEntryProvider = Provider((_) => _addHistoryEntry);
Future<void> _addHistoryEntry(Map<String, dynamic> data) =>
    ApiService.dio.post('/health-records/history', data: data);

final editHistoryEntryProvider = Provider((_) => _editHistoryEntry);
Future<void> _editHistoryEntry(String entryId, Map<String, dynamic> data) =>
    ApiService.dio.patch('/health-records/history/$entryId', data: data);

//  VITALS (record new) 

final recordVitalsProvider = Provider((_) => _recordVitals);
Future<void> _recordVitals(Map<String, dynamic> data) =>
    ApiService.dio.post('/health-records/vitals', data: data);

//  FAMILY HISTORY 

final addFamilyHistoryProvider = Provider((_) => _addFamilyHistory);
Future<void> _addFamilyHistory(String patientId, Map<String, dynamic> data) =>
    ApiService.dio.post(
      '/health-records/$patientId/family-history',
      data: data,
    );

final editFamilyHistoryProvider = Provider((_) => _editFamilyHistory);
Future<void> _editFamilyHistory(
  String patientId,
  String entryId,
  Map<String, dynamic> data,
) => ApiService.dio.patch(
  '/health-records/$patientId/family-history/$entryId',
  data: data,
);

final deleteFamilyHistoryProvider = Provider((_) => _deleteFamilyHistory);
Future<void> _deleteFamilyHistory(String patientId, String entryId) =>
    ApiService.dio.delete('/health-records/$patientId/family-history/$entryId');

//  IMMUNISATIONS 

final recordImmunisationProvider = Provider((_) => _recordImmunisation);
Future<void> _recordImmunisation(Map<String, dynamic> data) =>
    ApiService.dio.post('/health-records/immunisations', data: data);

final editImmunisationProvider = Provider((_) => _editImmunisation);
Future<void> _editImmunisation(String immId, Map<String, dynamic> data) =>
    ApiService.dio.patch('/health-records/immunisations/$immId', data: data);


final patientPrescriptionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      patientId,
    ) async {
      final res = await ApiService.dio.get('/prescriptions/patient/$patientId');
      return List<Map<String, dynamic>>.from(res.data as List);
    });

final createDirectPrescriptionProvider = Provider(
  (_) => _createDirectPrescription,
);

Future<void> _createDirectPrescription(Map<String, dynamic> data) =>
    ApiService.dio.post('/prescriptions/direct', data: data);
