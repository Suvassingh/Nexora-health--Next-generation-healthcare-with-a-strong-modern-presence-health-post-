import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/providers/selected_patient_provider.dart';
import '../app_constants.dart';
import 'providers/patient_health_provider.dart'; 
import 'patient_health_record_screen.dart'; 

class DoctorPatientListScreen extends ConsumerWidget {
  const DoctorPatientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.myPatients,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(doctorPatientsProvider),
          ),
        ],
      ),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(e.toString(), style: const TextStyle(color: Colors.black45)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(doctorPatientsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
        data: (patients) {
          if (patients.isEmpty) {
            return  Center(
              child: Text(AppLocalizations.of(context)!.noPatientsYet,
                style: TextStyle(color: Colors.black45),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(doctorPatientsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = patients[i];
                final patientId = p['patient_id'] as String;
                final patientName = p['full_name'] as String?;
                final gender = p['gender'] as String?;
                final avatarUrl = p['avatar_url'] as String?;

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      
                      ref.read(selectedPatientIdProvider.notifier).state =
                          patientId;
                      ref.read(selectedPatientNameProvider.notifier).state =
                          patientName;
                    
                      Get.to(() => PatientHealthRecordScreen());
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppConstants.primaryColor
                                .withOpacity(.15),
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Text(
                                    (patientName ?? '?')[0].toUpperCase(),
                                    style: TextStyle(
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName ??
                                      AppLocalizations.of(context)!.unknown,

                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (gender != null)
                                  Text(
                                    gender,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
