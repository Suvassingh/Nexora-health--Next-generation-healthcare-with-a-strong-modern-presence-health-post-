import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/providers/patient_health_provider.dart';
import 'package:healthpost_app/providers/selected_patient_provider.dart';

import 'package:intl/intl.dart';
import '../app_constants.dart';

class PatientHealthRecordScreen extends ConsumerWidget {
  const PatientHealthRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(selectedPatientIdProvider);
    final patientName = ref.watch(selectedPatientNameProvider);

    if (patientId == null || patientId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          title: Text(AppLocalizations.of(context)!.healthRecord),
        ),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.noPatientSelected,
            style: const TextStyle(color: Colors.black45),
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(patientHealthSummaryProvider(patientId));
    final saveState = ref.watch(saveNotifierProvider);

    // Show global error snackbar if a save failed
    ref.listen<SaveState>(saveNotifierProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(saveNotifierProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context, ref, patientId, patientName),
      body: Stack(
        children: [
          summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                _buildError(context, ref, err.toString(), patientId),
            data: (summary) => RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(patientHealthSummaryProvider(patientId)),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFlags(summary, context),
                  const SizedBox(height: 12),
                  _buildProfile(summary, context),
                  const SizedBox(height: 12),
                  _buildLatestVitals(summary, context, ref, patientId),
                  const SizedBox(height: 12),
                  _buildAllergies(summary, context, ref, patientId),
                  const SizedBox(height: 12),
                  _buildConditions(summary, context, ref, patientId),
                  const SizedBox(height: 12),
                  _buildMedicalHistory(summary, context, ref, patientId),
                  const SizedBox(height: 12),
                  _buildImmunisations(summary, context, ref, patientId),
                  const SizedBox(height: 12),
                  _buildFamilyHistory(summary, context, ref, patientId),
                  const SizedBox(height: 12),
                  _buildPrescriptions(summary, context, ref, patientId),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Saving overlay
          if (saveState.isSaving)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  //  APP BAR 

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    String? patientName,
  ) {
    return AppBar(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      title: Text(
        patientName != null
            ? AppLocalizations.of(context)!.patientRecord(patientName)
            : AppLocalizations.of(context)!.healthRecord,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.invalidate(patientHealthSummaryProvider(patientId)),
        ),
        IconButton(
          icon: const Icon(Icons.switch_account),
          onPressed: () => _showPatientSwitcherSheet(context, ref),
          tooltip: 'Switch patient',
        ),
      ],
    );
  }

  //  PATIENT SWITCHER 

  void _showPatientSwitcherSheet(BuildContext context, WidgetRef ref) {
    final currentId = ref.read(selectedPatientIdProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.switchPatient,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: ref
                    .watch(doctorPatientsProvider)
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppLocalizations.of(context)!.couldNotLoadPatients}: $e',
                            ),
                          ],
                        ),
                      ),
                      data: (patients) {
                        if (patients.isEmpty) {
                          return Center(
                            child: Text(
                              AppLocalizations.of(context)!.noPatientsAssigned,
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: patients.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = patients[i];
                            final pid = p['patient_id'] as String;
                            final isCurrent = pid == currentId;
                            return Material(
                              color: isCurrent
                                  ? AppConstants.primaryColor.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ref
                                          .read(
                                            selectedPatientIdProvider.notifier,
                                          )
                                          .state =
                                      pid;
                                  ref
                                          .read(
                                            selectedPatientNameProvider
                                                .notifier,
                                          )
                                          .state =
                                      p['full_name'] as String?;
                                  Navigator.pop(context);
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
                                        backgroundColor: AppConstants
                                            .primaryColor
                                            .withOpacity(.15),
                                        backgroundImage: p['avatar_url'] != null
                                            ? NetworkImage(
                                                p['avatar_url'] as String,
                                              )
                                            : null,
                                        child: p['avatar_url'] == null
                                            ? Text(
                                                (p['full_name'] ?? '?')[0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color:
                                                      AppConstants.primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['full_name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (p['gender'] != null)
                                              Text(
                                                p['gender'] as String,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.current,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        )
                                      else
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
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  FLAGS 

  Widget _buildFlags(Map<String, dynamic> summary, BuildContext context) {
    final flags = Map<String, dynamic>.from(summary['flags'] ?? {});
    final active = <_Flag>[];
    if (flags['has_severe_allergy'] == true)
      active.add(
        _Flag(
          Icons.warning_rounded,
          AppLocalizations.of(context)!.severeAllergyFlag,
          Colors.red.shade700,
        ),
      );
    if (flags['low_spo2'] == true)
      active.add(
        _Flag(
          Icons.air,
          AppLocalizations.of(context)!.lowSpo2Flag,
          Colors.red.shade700,
        ),
      );
    if (flags['has_active_condition'] == true)
      active.add(
        _Flag(
          Icons.favorite_border,
          AppLocalizations.of(context)!.activeConditionFlag,
          Colors.orange.shade700,
        ),
      );
    if (flags['has_overdue_vaccine'] == true)
      active.add(
        _Flag(
          Icons.vaccines,
          AppLocalizations.of(context)!.overdueVaccineFlag,
          Colors.orange.shade700,
        ),
      );
    if (active.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(children: active.map(_buildFlagTile).toList()),
    );
  }

  Widget _buildFlagTile(_Flag f) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(f.icon, color: f.color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            f.label,
            style: TextStyle(
              fontSize: 13,
              color: f.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  //  PROFILE (read-only) 

  Widget _buildProfile(Map<String, dynamic> summary, BuildContext context) {
    final p = Map<String, dynamic>.from(summary['profile'] ?? {});
    return _Card(
      title: AppLocalizations.of(context)!.patient,
      icon: Icons.person_outline,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppConstants.primaryColor.withOpacity(.15),
                backgroundImage: p['avatar_url'] != null
                    ? NetworkImage(p['avatar_url'] as String)
                    : null,
                child: p['avatar_url'] == null
                    ? Text(
                        (p['full_name'] ?? '?')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 22,
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
                      p['full_name'] ?? '—',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (p['age'] != null)
                      Text(
                        '${p['age']} yrs · ${p['gender'] ?? '—'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              if (p['blood_group'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    p['blood_group'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
            ],
          ),
          if (p['district'] != null || p['municipality'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.black38,
                ),
                const SizedBox(width: 4),
                Text(
                  [
                    p['municipality'],
                    p['district'],
                    p['province'],
                  ].whereType<String>().join(', '),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  //  VITALS 

  Widget _buildLatestVitals(
    Map<String, dynamic> summary,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final v = Map<String, dynamic>.from(summary['vitals']?['latest'] ?? {});
    final vitalsId = v['id'] as String?;

    final tiles = [
      if (v['bp_systolic'] != null && v['bp_diastolic'] != null)
        _VitalTile(
          'BP',
          '${v['bp_systolic']}/${v['bp_diastolic']} mmHg',
          Icons.favorite,
        ),
      if (v['heart_rate'] != null)
        _VitalTile('HR', '${v['heart_rate']} bpm', Icons.monitor_heart),
      if (v['spo2'] != null) _VitalTile('SpO₂', '${v['spo2']}%', Icons.air),
      if (v['temperature_c'] != null)
        _VitalTile('Temp', '${v['temperature_c']}°C', Icons.thermostat),
      if (v['weight_kg'] != null)
        _VitalTile('Wt', '${v['weight_kg']} kg', Icons.monitor_weight),
      if (v['height_cm'] != null)
        _VitalTile('Ht', '${v['height_cm']} cm', Icons.height),
    ];

    return _Card(
      title: 'Latest Vitals',
      icon: Icons.monitor_heart_outlined,
      subtitle: v['recorded_at'] != null
          ? _fmt(v['recorded_at'] as String?)
          : null,
      trailing: _EditAddButton(
        onEdit: vitalsId == null
            ? null
            : () => _showVitalsSheet(context, ref, patientId, vitalsId, v),
        onAdd: () => _showVitalsSheet(context, ref, patientId, null, {}),
        addLabel: 'Record Vitals',
      ),
      child: tiles.isEmpty
          ? const Text(
              'No vitals recorded.',
              style: TextStyle(color: Colors.black45),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tiles.map((t) => _buildVitalChip(t)).toList(),
            ),
    );
  }

  Widget _buildVitalChip(_VitalTile t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(t.icon, size: 13, color: Colors.blue.shade700),
        const SizedBox(width: 4),
        Text(
          t.label,
          style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 4),
        Text(
          t.value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  //  ALLERGIES 

  Widget _buildAllergies(
    Map<String, dynamic> summary,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final list = (summary['allergies'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return _Card(
      title: AppLocalizations.of(context)!.allergies,
      icon: Icons.warning_amber_outlined,
      count: list.length,
      trailing: _EditAddButton(
        onAdd: () => _showAllergySheet(context, ref, patientId, null, {}),
        addLabel: 'Add Allergy',
      ),
      child: list.isEmpty
          ? const Text(
              'None recorded.',
              style: TextStyle(color: Colors.black45),
            )
          : Column(
              children: list
                  .map((a) => _buildAllergyTile(a, context, ref, patientId))
                  .toList(),
            ),
    );
  }

  Widget _buildAllergyTile(
    Map<String, dynamic> a,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _severityColor(a['severity'] as String?),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['allergen'] as String? ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (a['reaction'] != null)
                  Text(
                    a['reaction'] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
              ],
            ),
          ),
          Text(
            a['severity'] as String? ?? '',
            style: TextStyle(
              fontSize: 11,
              color: _severityColor(a['severity'] as String?),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showAllergySheet(
              context,
              ref,
              patientId,
              a['id'] as String?,
              a,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  //  CONDITIONS 

  Widget _buildConditions(
    Map<String, dynamic> summary,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final list = (summary['conditions'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return _Card(
      title: AppLocalizations.of(context)!.chronicConditions,
      icon: Icons.health_and_safety_outlined,
      count: list.length,
      trailing: _EditAddButton(
        onAdd: () => _showConditionSheet(context, ref, patientId, null, {}),
        addLabel: 'Add Condition',
      ),
      child: list.isEmpty
          ? const Text(
              'None recorded.',
              style: TextStyle(color: Colors.black45),
            )
          : Column(
              children: list
                  .map((c) => _buildConditionTile(c, context, ref, patientId))
                  .toList(),
            ),
    );
  }

  Widget _buildConditionTile(
    Map<String, dynamic> c,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c['status'] == 'active'
                  ? Colors.orange
                  : Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['condition_name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (c['icd_code'] != null)
                  Text(
                    'ICD: ${c['icd_code']}',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
              ],
            ),
          ),
          Text(
            c['status'] as String? ?? '',
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showConditionSheet(
              context,
              ref,
              patientId,
              c['id'] as String?,
              c,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  //  MEDICAL HISTORY 

  Widget _buildMedicalHistory(
    Map<String, dynamic> summary,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final list = (summary['medical_history'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    const int _previewCount = 5;
    final bool hasMore = list.length > _previewCount;

    return _Card(
      title: AppLocalizations.of(context)!.pastConsultations,
      icon: Icons.history,
      count: list.length,
      trailing: _EditAddButton(
        onAdd: () => _showHistorySheet(context, ref, patientId, null, {}),
        addLabel: 'Add Entry',
      ),
      child: list.isEmpty
          ? Text(
              AppLocalizations.of(context)!.noHistoryYet,
              style: const TextStyle(color: Colors.black45),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...list
                    .take(_previewCount)
                    .map((h) => _buildHistoryTile(h, context, ref, patientId)),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: () =>
                          _showAllHistorySheet(context, ref, patientId, list),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Show all ${list.length} consultations',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showAllHistorySheet(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    List<Map<String, dynamic>> list,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'All Consultations',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: list
                    .map((h) => _buildHistoryTile(h, ctx, ref, patientId))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(
    Map<String, dynamic> h,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final doctorName =
        h['doctors']?['user_profiles']?['full_name'] as String? ??
        AppLocalizations.of(context)!.unknownDoctor;
    final specialty = h['doctors']?['specialty'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(h['created_at'] as String?),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
              Row(
                children: [
                  if (h['consultation_type'] != null)
                    _TypeBadge(h['consultation_type'] as String),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showHistorySheet(
                      context,
                      ref,
                      patientId,
                      h['id'] as String?,
                      h,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            h['diagnosis'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (h['chief_complaint'] != null) ...[
            const SizedBox(height: 2),
            Text(
              h['chief_complaint'] as String,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Dr. $doctorName · $specialty',
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  //  IMMUNISATIONS 

  Widget _buildImmunisations(
    Map<String, dynamic> summary,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final list = (summary['immunisations'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return _Card(
      title: AppLocalizations.of(context)!.immunisations,
      icon: Icons.vaccines_outlined,
      count: list.length,
      trailing: _EditAddButton(
        onAdd: () => _showImmunisationSheet(context, ref, patientId, null, {}),
        addLabel: 'Record Vaccine',
      ),
      child: list.isEmpty
          ? const Text(
              'None recorded.',
              style: TextStyle(color: Colors.black45),
            )
          : Column(
              children: list
                  .take(6)
                  .map(
                    (i) => _buildImmunisationTile(i, context, ref, patientId),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildImmunisationTile(
    Map<String, dynamic> imm,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final overdue = imm['overdue'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            overdue ? Icons.warning_rounded : Icons.check_circle_outline,
            size: 16,
            color: overdue ? Colors.orange : Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${imm['vaccine_name']} (dose ${imm['dose_number']})',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            _fmt(imm['administered_at'] as String?),
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showImmunisationSheet(
              context,
              ref,
              patientId,
              imm['id'] as String?,
              imm,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  //  FAMILY HISTORY 

  Widget _buildFamilyHistory(
    Map<String, dynamic> summary,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final list = (summary['family_history'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return _Card(
      title: AppLocalizations.of(context)!.familyHistory,
      icon: Icons.people_outline,
      count: list.length,
      trailing: _EditAddButton(
        onAdd: () => _showFamilyHistorySheet(context, ref, patientId, null, {}),
        addLabel: 'Add Entry',
      ),
      child: list.isEmpty
          ? const Text(
              'None recorded.',
              style: TextStyle(color: Colors.black45),
            )
          : Column(
              children: list
                  .map((f) => _buildFamilyTile(f, context, ref, patientId))
                  .toList(),
            ),
    );
  }

  Widget _buildFamilyTile(
    Map<String, dynamic> f,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              f['relation'] as String? ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: Text(
              f['condition'] as String? ?? '',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => _showFamilyHistorySheet(
              context,
              ref,
              patientId,
              f['id'] as String?,
              f,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: Colors.black38,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              final confirmed = await _confirmDelete(context);
              if (confirmed && context.mounted) {
                final del = ref.read(deleteFamilyHistoryProvider);
                ref
                    .read(saveNotifierProvider.notifier)
                    .run(
                      () => del(patientId, f['id'] as String),
                      patientId: patientId,
                    );
              }
            },
            child: const Icon(
              Icons.delete_outline,
              size: 15,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  //  PRESCRIPTIONS (moved here from top-level) 

  Widget _buildPrescriptions(
    Map<String, dynamic> summary,
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    final prescriptionsAsync = ref.watch(
      patientPrescriptionsProvider(patientId),
    );
    return _Card(
      title: 'Prescriptions',
      icon: Icons.medication_outlined,
      count: summary['prescriptions']?['total'] as int? ?? 0,
      trailing: _EditAddButton(
        onAdd: () => _showPrescriptionSheet(context, ref, patientId),
        addLabel: 'Prescribe',
      ),
      child: prescriptionsAsync.when(
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const Text(
          'Could not load prescriptions.',
          style: TextStyle(color: Colors.black45),
        ),
        data: (list) => list.isEmpty
            ? const Text(
                'No prescriptions yet.',
                style: TextStyle(color: Colors.black45),
              )
            : Column(
                children: list
                    .take(3)
                    .map((p) => _buildPrescriptionTile(p, context))
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildPrescriptionTile(Map<String, dynamic> p, BuildContext context) {
    final items = (p['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final doctorName =
        p['doctors']?['user_profiles']?['full_name'] as String? ??
        'Unknown Doctor';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(p['issued_at'] as String?),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
              if (p['follow_up_date'] != null)
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 11,
                      color: Colors.black38,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Follow-up: ${_fmt(p['follow_up_date'] as String?)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Diagnosis
          Text(
            p['diagnosis'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          // Medicine chips
          if (items.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: items.map((item) => _buildMedicineChip(item)).toList(),
            ),
          const SizedBox(height: 4),
          Text(
            'Dr. $doctorName',
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineChip(Map<String, dynamic> item) {
    final name = item['medicine_name'] as String? ?? '';
    final dosage = item['dosage'] as String?;
    final frequency = item['frequency'] as String?;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          if (dosage != null || frequency != null)
            Text(
              [dosage, frequency].whereType<String>().join(' · '),
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
        ],
      ),
    );
  }
  //  EDIT BOTTOM SHEETS
  void _showPrescriptionSheet(
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PrescriptionSheet(patientId: patientId),
    );
  }

  void _showVitalsSheet(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    String? vitalsId,
    Map<String, dynamic> existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _VitalsEditSheet(
        patientId: patientId,
        vitalsId: vitalsId,
        existing: existing,
      ),
    );
  }

  void _showAllergySheet(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    String? allergyId,
    Map<String, dynamic> existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AllergyEditSheet(
        patientId: patientId,
        allergyId: allergyId,
        existing: existing,
      ),
    );
  }

  void _showConditionSheet(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    String? conditionId,
    Map<String, dynamic> existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ConditionEditSheet(
        patientId: patientId,
        conditionId: conditionId,
        existing: existing,
      ),
    );
  }

  void _showHistorySheet(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    String? entryId,
    Map<String, dynamic> existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HistoryEditSheet(
        patientId: patientId,
        entryId: entryId,
        existing: existing,
      ),
    );
  }

  void _showImmunisationSheet(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    String? immId,
    Map<String, dynamic> existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ImmunisationEditSheet(
        patientId: patientId,
        immId: immId,
        existing: existing,
      ),
    );
  }

  void _showFamilyHistorySheet(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    String? entryId,
    Map<String, dynamic> existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FamilyHistoryEditSheet(
        patientId: patientId,
        entryId: entryId,
        existing: existing,
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    String message,
    String patientId,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.couldNotLoadRecord,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black38),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(patientHealthSummaryProvider(patientId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat.yMMMd().format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  Color _severityColor(String? s) {
    switch (s) {
      case 'severe':
        return Colors.red.shade700;
      case 'moderate':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Entry'),
            content: const Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

//  EDIT BOTTOM SHEETS (OUTSIDE CLASS)
/// Shared scaffold for all edit sheets.
class _EditSheet extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;
  final bool isLoading;

  const _EditSheet({
    required this.title,
    required this.fields,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ...fields,
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

//  VITALS SHEET 

class _VitalsEditSheet extends ConsumerStatefulWidget {
  final String patientId;
  final String? vitalsId; // null = new record
  final Map<String, dynamic> existing;

  const _VitalsEditSheet({
    required this.patientId,
    required this.vitalsId,
    required this.existing,
  });

  @override
  ConsumerState<_VitalsEditSheet> createState() => _VitalsEditSheetState();
}

class _VitalsEditSheetState extends ConsumerState<_VitalsEditSheet> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _bpSys;
  late final TextEditingController _bpDia;
  late final TextEditingController _hr;
  late final TextEditingController _spo2;
  late final TextEditingController _temp;
  late final TextEditingController _wt;
  late final TextEditingController _ht;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bpSys = TextEditingController(
      text: widget.existing['bp_systolic']?.toString() ?? '',
    );
    _bpDia = TextEditingController(
      text: widget.existing['bp_diastolic']?.toString() ?? '',
    );
    _hr = TextEditingController(
      text: widget.existing['heart_rate']?.toString() ?? '',
    );
    _spo2 = TextEditingController(
      text: widget.existing['spo2']?.toString() ?? '',
    );
    _temp = TextEditingController(
      text: widget.existing['temperature_c']?.toString() ?? '',
    );
    _wt = TextEditingController(
      text: widget.existing['weight_kg']?.toString() ?? '',
    );
    _ht = TextEditingController(
      text: widget.existing['height_cm']?.toString() ?? '',
    );
    _notes = TextEditingController(
      text: widget.existing['notes'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _bpSys.dispose();
    _bpDia.dispose();
    _hr.dispose();
    _spo2.dispose();
    _temp.dispose();
    _wt.dispose();
    _ht.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    int? _parseInt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());
    double? _parseDouble(TextEditingController c) =>
        c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

    final data = <String, dynamic>{
      if (_bpSys.text.isNotEmpty) 'bp_systolic': _parseInt(_bpSys),
      if (_bpDia.text.isNotEmpty) 'bp_diastolic': _parseInt(_bpDia),
      if (_hr.text.isNotEmpty) 'heart_rate': _parseInt(_hr),
      if (_spo2.text.isNotEmpty) 'spo2': _parseInt(_spo2),
      if (_temp.text.isNotEmpty) 'temperature_c': _parseDouble(_temp),
      if (_wt.text.isNotEmpty) 'weight_kg': _parseDouble(_wt),
      if (_ht.text.isNotEmpty) 'height_cm': _parseDouble(_ht),
      if (_notes.text.isNotEmpty) 'notes': _notes.text.trim(),
    };

    bool ok;
    if (widget.vitalsId == null) {
      // New record
      data['patient_id'] = widget.patientId;
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(recordVitalsProvider)(data),
            patientId: widget.patientId,
          );
    } else {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(updateVitalsProvider)(widget.vitalsId!, data),
            patientId: widget.patientId,
          );
    }

    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _EditSheet(
      title: widget.vitalsId == null ? 'Record Vitals' : 'Edit Vitals',
      isLoading: _saving,
      onSave: _save,
      fields: [
        Form(
          key: _form,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _NumField(controller: _bpSys, label: 'Systolic BP'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumField(controller: _bpDia, label: 'Diastolic BP'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NumField(
                      controller: _hr,
                      label: 'Heart Rate (bpm)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumField(controller: _spo2, label: 'SpO₂ %'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NumField(controller: _temp, label: 'Temp (°C)'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumField(controller: _wt, label: 'Weight (kg)'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumField(controller: _ht, label: 'Height (cm)'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TextField(controller: _notes, label: 'Notes', maxLines: 2),
            ],
          ),
        ),
      ],
    );
  }
}

//  ALLERGY SHEET 

class _AllergyEditSheet extends ConsumerStatefulWidget {
  final String patientId;
  final String? allergyId;
  final Map<String, dynamic> existing;
  const _AllergyEditSheet({
    required this.patientId,
    required this.allergyId,
    required this.existing,
  });
  @override
  ConsumerState<_AllergyEditSheet> createState() => _AllergyEditSheetState();
}

class _AllergyEditSheetState extends ConsumerState<_AllergyEditSheet> {
  late final TextEditingController _allergen;
  late final TextEditingController _reaction;
  late final TextEditingController _notes;
  late String _severity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _allergen = TextEditingController(
      text: widget.existing['allergen'] as String? ?? '',
    );
    _reaction = TextEditingController(
      text: widget.existing['reaction'] as String? ?? '',
    );
    _notes = TextEditingController(
      text: widget.existing['notes'] as String? ?? '',
    );
    _severity = (widget.existing['severity'] as String?) ?? 'moderate';
  }

  @override
  void dispose() {
    _allergen.dispose();
    _reaction.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_allergen.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final data = {
      'allergen': _allergen.text.trim(),
      'reaction': _reaction.text.trim().isEmpty ? null : _reaction.text.trim(),
      'severity': _severity,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };
    bool ok;
    if (widget.allergyId == null) {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(addAllergyProvider)(widget.patientId, data),
            patientId: widget.patientId,
          );
    } else {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(editAllergyProvider)(
              widget.patientId,
              widget.allergyId!,
              data,
            ),
            patientId: widget.patientId,
          );
    }
    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _EditSheet(
      title: widget.allergyId == null ? 'Add Allergy' : 'Edit Allergy',
      isLoading: _saving,
      onSave: _save,
      fields: [
        _TextField(controller: _allergen, label: 'Allergen *'),
        const SizedBox(height: 12),
        _TextField(controller: _reaction, label: 'Reaction'),
        const SizedBox(height: 12),
        _DropdownField<String>(
          label: 'Severity',
          value: _severity,
          items: const ['mild', 'moderate', 'severe'],
          labelOf: (s) => s[0].toUpperCase() + s.substring(1),
          onChanged: (v) => setState(() => _severity = v!),
        ),
        const SizedBox(height: 12),
        _TextField(controller: _notes, label: 'Notes', maxLines: 2),
      ],
    );
  }
}

//  CONDITION SHEET 

class _ConditionEditSheet extends ConsumerStatefulWidget {
  final String patientId;
  final String? conditionId;
  final Map<String, dynamic> existing;
  const _ConditionEditSheet({
    required this.patientId,
    required this.conditionId,
    required this.existing,
  });
  @override
  ConsumerState<_ConditionEditSheet> createState() =>
      _ConditionEditSheetState();
}

class _ConditionEditSheetState extends ConsumerState<_ConditionEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _icd;
  late final TextEditingController _notes;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.existing['condition_name'] as String? ?? '',
    );
    _icd = TextEditingController(
      text: widget.existing['icd_code'] as String? ?? '',
    );
    _notes = TextEditingController(
      text: widget.existing['notes'] as String? ?? '',
    );
    _status = (widget.existing['status'] as String?) ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _icd.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final data = {
      'condition_name': _name.text.trim(),
      if (_icd.text.isNotEmpty) 'icd_code': _icd.text.trim(),
      'status': _status,
      if (_notes.text.isNotEmpty) 'notes': _notes.text.trim(),
    };
    bool ok;
    if (widget.conditionId == null) {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(addConditionProvider)(widget.patientId, data),
            patientId: widget.patientId,
          );
    } else {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(editConditionProvider)(
              widget.patientId,
              widget.conditionId!,
              data,
            ),
            patientId: widget.patientId,
          );
    }
    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _EditSheet(
      title: widget.conditionId == null ? 'Add Condition' : 'Edit Condition',
      isLoading: _saving,
      onSave: _save,
      fields: [
        _TextField(controller: _name, label: 'Condition Name *'),
        const SizedBox(height: 12),
        _TextField(controller: _icd, label: 'ICD Code'),
        const SizedBox(height: 12),
        _DropdownField<String>(
          label: 'Status',
          value: _status,
          items: const ['active', 'managed', 'resolved'],
          labelOf: (s) => s[0].toUpperCase() + s.substring(1),
          onChanged: (v) => setState(() => _status = v!),
        ),
        const SizedBox(height: 12),
        _TextField(controller: _notes, label: 'Notes', maxLines: 2),
      ],
    );
  }
}

//  HISTORY SHEET 

class _HistoryEditSheet extends ConsumerStatefulWidget {
  final String patientId;
  final String? entryId;
  final Map<String, dynamic> existing;
  const _HistoryEditSheet({
    required this.patientId,
    required this.entryId,
    required this.existing,
  });
  @override
  ConsumerState<_HistoryEditSheet> createState() => _HistoryEditSheetState();
}

class _HistoryEditSheetState extends ConsumerState<_HistoryEditSheet> {
  late final TextEditingController _complaint;
  late final TextEditingController _diagnosis;
  late final TextEditingController _icd;
  late final TextEditingController _treatment;
  late final TextEditingController _hoi;
  late final TextEditingController _exam;
  late final TextEditingController _followUp;
  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rawType =
        widget.existing['consultation_type'] as String? ?? 'in_person';
    _type = ['in_person', 'video', 'chat', 'audio'].contains(rawType)
        ? rawType
        : 'in_person';
    _complaint = TextEditingController(
      text: widget.existing['chief_complaint'] as String? ?? '',
    );
    _diagnosis = TextEditingController(
      text: widget.existing['diagnosis'] as String? ?? '',
    );
    _icd = TextEditingController(
      text: widget.existing['icd_code'] as String? ?? '',
    );
    _treatment = TextEditingController(
      text: widget.existing['treatment_plan'] as String? ?? '',
    );
    _hoi = TextEditingController(
      text: widget.existing['history_of_illness'] as String? ?? '',
    );
    _exam = TextEditingController(
      text: widget.existing['examination_notes'] as String? ?? '',
    );
    _followUp = TextEditingController(
      text: widget.existing['follow_up_days']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _complaint.dispose();
    _diagnosis.dispose();
    _icd.dispose();
    _treatment.dispose();
    _hoi.dispose();
    _exam.dispose();
    _followUp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_diagnosis.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      if (_complaint.text.isNotEmpty) 'chief_complaint': _complaint.text.trim(),
      'diagnosis': _diagnosis.text.trim(),
      if (_icd.text.isNotEmpty) 'icd_code': _icd.text.trim(),
      if (_treatment.text.isNotEmpty) 'treatment_plan': _treatment.text.trim(),
      if (_hoi.text.isNotEmpty) 'history_of_illness': _hoi.text.trim(),
      if (_exam.text.isNotEmpty) 'examination_notes': _exam.text.trim(),
      if (_followUp.text.isNotEmpty)
        'follow_up_days': int.tryParse(_followUp.text.trim()),
      'consultation_type': _type,
    };
    bool ok;
    if (widget.entryId == null) {
      data['patient_id'] = widget.patientId;
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(addHistoryEntryProvider)(data),
            patientId: widget.patientId,
          );
    } else {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(editHistoryEntryProvider)(widget.entryId!, data),
            patientId: widget.patientId,
          );
    }
    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _EditSheet(
      title: widget.entryId == null ? 'Add Consultation' : 'Edit Consultation',
      isLoading: _saving,
      onSave: _save,
      fields: [
        _TextField(controller: _complaint, label: 'Chief Complaint'),
        const SizedBox(height: 12),
        _TextField(controller: _diagnosis, label: 'Diagnosis *'),
        const SizedBox(height: 12),
        _TextField(controller: _icd, label: 'ICD Code'),
        const SizedBox(height: 12),
        _TextField(controller: _hoi, label: 'History of Illness', maxLines: 3),
        const SizedBox(height: 12),
        _TextField(controller: _exam, label: 'Examination Notes', maxLines: 3),
        const SizedBox(height: 12),
        _TextField(
          controller: _treatment,
          label: 'Treatment Plan',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _NumField(controller: _followUp, label: 'Follow-up (days)'),
        const SizedBox(height: 12),
        _DropdownField<String>(
          label: 'Consultation Type',
          value: _type,
          items: const ['in_person', 'video', 'chat', "audio"],
          labelOf: (s) => s.replaceAll('_', ' '),
          onChanged: (v) => setState(() => _type = v!),
        ),
      ],
    );
  }
}

//  IMMUNISATION SHEET 

class _ImmunisationEditSheet extends ConsumerStatefulWidget {
  final String patientId;
  final String? immId;
  final Map<String, dynamic> existing;
  const _ImmunisationEditSheet({
    required this.patientId,
    required this.immId,
    required this.existing,
  });
  @override
  ConsumerState<_ImmunisationEditSheet> createState() =>
      _ImmunisationEditSheetState();
}

class _ImmunisationEditSheetState
    extends ConsumerState<_ImmunisationEditSheet> {
  late final TextEditingController _vaccine;
  late final TextEditingController _dose;
  late final TextEditingController _batch;
  late final TextEditingController _notes;
  late DateTime? _administeredAt;
  late DateTime? _nextDue;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _vaccine = TextEditingController(
      text: widget.existing['vaccine_name'] as String? ?? '',
    );
    _dose = TextEditingController(
      text: widget.existing['dose_number']?.toString() ?? '1',
    );
    _batch = TextEditingController(
      text: widget.existing['batch_number'] as String? ?? '',
    );
    _notes = TextEditingController(
      text: widget.existing['notes'] as String? ?? '',
    );

    final administeredStr = widget.existing['administered_at'] as String?;
    _administeredAt = administeredStr != null
        ? DateTime.tryParse(administeredStr)
        : null;

    final nextDueStr = widget.existing['next_due_date'] as String?;
    _nextDue = nextDueStr != null ? DateTime.tryParse(nextDueStr) : null;
  }

  @override
  void dispose() {
    _vaccine.dispose();
    _dose.dispose();
    _batch.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_vaccine.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'vaccine_name': _vaccine.text.trim(),
      'dose_number': int.tryParse(_dose.text.trim()) ?? 1,
      if (_batch.text.isNotEmpty) 'batch_number': _batch.text.trim(),
      if (_administeredAt != null)
        'administered_at': _administeredAt!.toIso8601String(),
      if (_nextDue != null)
        'next_due_date': _nextDue!.toIso8601String().split('T')[0],
      if (_notes.text.isNotEmpty) 'notes': _notes.text.trim(),
    };
    bool ok;
    if (widget.immId == null) {
      data['patient_id'] = widget.patientId;
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(recordImmunisationProvider)(data),
            patientId: widget.patientId,
          );
    } else {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(editImmunisationProvider)(widget.immId!, data),
            patientId: widget.patientId,
          );
    }
    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _pickDate(bool isAdministered) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          (isAdministered ? _administeredAt : _nextDue) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: isAdministered
          ? DateTime.now()
          : DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        if (isAdministered) {
          _administeredAt = picked;
        } else {
          _nextDue = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return _EditSheet(
      title: widget.immId == null ? 'Record Vaccine' : 'Edit Vaccine',
      isLoading: _saving,
      onSave: _save,
      fields: [
        _TextField(controller: _vaccine, label: 'Vaccine Name *'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NumField(controller: _dose, label: 'Dose Number'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TextField(controller: _batch, label: 'Batch No.'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DatePickerTile(
          label: 'Administered On',
          date: _administeredAt,
          formatted: _administeredAt != null
              ? df.format(_administeredAt!)
              : null,
          onTap: () => _pickDate(true),
        ),
        const SizedBox(height: 8),
        _DatePickerTile(
          label: 'Next Due Date',
          date: _nextDue,
          formatted: _nextDue != null ? df.format(_nextDue!) : null,
          onTap: () => _pickDate(false),
        ),
        const SizedBox(height: 12),
        _TextField(controller: _notes, label: 'Notes', maxLines: 2),
      ],
    );
  }
}

//  FAMILY HISTORY SHEET 

class _FamilyHistoryEditSheet extends ConsumerStatefulWidget {
  final String patientId;
  final String? entryId;
  final Map<String, dynamic> existing;
  const _FamilyHistoryEditSheet({
    required this.patientId,
    required this.entryId,
    required this.existing,
  });
  @override
  ConsumerState<_FamilyHistoryEditSheet> createState() =>
      _FamilyHistoryEditSheetState();
}

class _FamilyHistoryEditSheetState
    extends ConsumerState<_FamilyHistoryEditSheet> {
  late final TextEditingController _relation;
  late final TextEditingController _condition;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _relation = TextEditingController(
      text: widget.existing['relation'] as String? ?? '',
    );
    _condition = TextEditingController(
      text: widget.existing['condition'] as String? ?? '',
    );
    _notes = TextEditingController(
      text: widget.existing['notes'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _relation.dispose();
    _condition.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_relation.text.trim().isEmpty || _condition.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final data = {
      'relation': _relation.text.trim(),
      'condition': _condition.text.trim(),
      if (_notes.text.isNotEmpty) 'notes': _notes.text.trim(),
    };
    bool ok;
    if (widget.entryId == null) {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(addFamilyHistoryProvider)(widget.patientId, data),
            patientId: widget.patientId,
          );
    } else {
      ok = await ref
          .read(saveNotifierProvider.notifier)
          .run(
            () => ref.read(editFamilyHistoryProvider)(
              widget.patientId,
              widget.entryId!,
              data,
            ),
            patientId: widget.patientId,
          );
    }
    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _EditSheet(
      title: widget.entryId == null
          ? 'Add Family History'
          : 'Edit Family History',
      isLoading: _saving,
      onSave: _save,
      fields: [
        _TextField(controller: _relation, label: 'Relation *'),
        const SizedBox(height: 12),
        _TextField(controller: _condition, label: 'Condition *'),
        const SizedBox(height: 12),
        _TextField(controller: _notes, label: 'Notes', maxLines: 2),
      ],
    );
  }
}

//  PRESCRIPTION SHEET (moved here from inside class) 

class _PrescriptionSheet extends ConsumerStatefulWidget {
  final String patientId;
  const _PrescriptionSheet({required this.patientId});

  @override
  ConsumerState<_PrescriptionSheet> createState() => _PrescriptionSheetState();
}

class _PrescriptionSheetState extends ConsumerState<_PrescriptionSheet> {
  final _diagnosis = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _followUpDate;
  bool _saving = false;

  // Each medicine row: {name, dosage, frequency, duration_days, instructions}
  final List<Map<String, TextEditingController>> _items = [];

  @override
  void initState() {
    super.initState();
    _addItem(); // start with one empty row
  }

  void _addItem() {
    setState(() {
      _items.add({
        'name': TextEditingController(),
        'dosage': TextEditingController(),
        'frequency': TextEditingController(),
        'duration': TextEditingController(),
        'instructions': TextEditingController(),
      });
    });
  }

  void _removeItem(int index) {
    final row = _items.removeAt(index);
    for (final c in row.values) {
      c.dispose();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _diagnosis.dispose();
    _notes.dispose();
    for (final row in _items) {
      for (final c in row.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_diagnosis.text.trim().isEmpty) return;

    final validItems = _items
        .where((row) => row['name']!.text.trim().isNotEmpty)
        .toList();

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'patient_id': widget.patientId,
      'diagnosis': _diagnosis.text.trim(),
      if (_notes.text.isNotEmpty) 'notes': _notes.text.trim(),
      if (_followUpDate != null)
        'follow_up_date': _followUpDate!.toIso8601String().split('T')[0],
      'items': validItems
          .map(
            (row) => {
              'medicine_name': row['name']!.text.trim(),
              if (row['dosage']!.text.isNotEmpty)
                'dosage': row['dosage']!.text.trim(),
              if (row['frequency']!.text.isNotEmpty)
                'frequency': row['frequency']!.text.trim(),
              if (row['duration']!.text.isNotEmpty)
                'duration_days': int.tryParse(row['duration']!.text.trim()),
              if (row['instructions']!.text.isNotEmpty)
                'instructions': row['instructions']!.text.trim(),
            },
          )
          .toList(),
    };

    final ok = await ref
        .read(saveNotifierProvider.notifier)
        .run(
          () => ref.read(createDirectPrescriptionProvider)(payload),
          patientId: widget.patientId,
        );

    // Also invalidate the prescriptions list
    ref.invalidate(patientPrescriptionsProvider(widget.patientId));

    setState(() => _saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _pickFollowUp() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Write Prescription',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // Diagnosis
              _TextField(controller: _diagnosis, label: 'Diagnosis *'),
              const SizedBox(height: 12),

              // Notes
              _TextField(controller: _notes, label: 'Notes', maxLines: 2),
              const SizedBox(height: 12),

              // Follow-up date
              _DatePickerTile(
                label: 'Follow-up Date',
                date: _followUpDate,
                formatted: _followUpDate != null
                    ? DateFormat.yMMMd().format(_followUpDate!)
                    : null,
                onTap: _pickFollowUp,
              ),
              const SizedBox(height: 20),

              // Medicines header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Medicines',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _addItem,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Medicine',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Medicine rows
              ..._items.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TextField(
                              controller: row['name']!,
                              label: 'Medicine Name *',
                            ),
                          ),
                          if (_items.length > 1) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeItem(i),
                              child: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TextField(
                              controller: row['dosage']!,
                              label: 'Dosage',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TextField(
                              controller: row['frequency']!,
                              label: 'Frequency',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NumField(
                              controller: row['duration']!,
                              label: 'Days',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _TextField(
                        controller: row['instructions']!,
                        label: 'Instructions',
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Prescription',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  REUSABLE FORM FIELD WIDGETS
class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _NumField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(labelOf(i))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String? formatted;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.formatted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
        ),
        child: Text(
          formatted ?? 'Tap to select',
          style: TextStyle(
            fontSize: 14,
            color: formatted != null ? Colors.black87 : Colors.black38,
          ),
        ),
      ),
    );
  }
}

//  REUSABLE UI COMPONENTS (unchanged from original)
class _Flag {
  final IconData icon;
  final String label;
  final Color color;
  const _Flag(this.icon, this.label, this.color);
}

class _VitalTile {
  final String label;
  final String value;
  final IconData icon;
  const _VitalTile(this.label, this.value, this.icon);
}

/// Small "+ Add" / " Edit" button shown in card headers.
class _EditAddButton extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onAdd;
  final String? addLabel;

  const _EditAddButton({this.onEdit, this.onAdd, this.addLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 12,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (onEdit != null && onAdd != null) const SizedBox(width: 6),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 12, color: Colors.green.shade700),
                  const SizedBox(width: 3),
                  Text(
                    addLabel ?? 'Add',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final int? count;
  final Widget child;
  final Widget? trailing;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (count != null && count! > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    const colors = {
      'video': Colors.blue,
      'chat': Colors.purple,
      'in_person': Colors.teal,
      'audio': Colors.orange,
    };
    const icons = {
      'video': Icons.videocam_outlined,
      'chat': Icons.chat_bubble_outline,
      'in_person': Icons.local_hospital_outlined,
      'audio': Icons.headset_mic_outlined,
    };
    final c = colors[type] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[type] ?? Icons.circle, size: 10, color: c),
          const SizedBox(width: 3),
          Text(
            type.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 10,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
