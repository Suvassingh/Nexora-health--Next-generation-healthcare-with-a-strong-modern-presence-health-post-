import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/services/selected_patient_provider.dart';
import 'package:intl/intl.dart';
import '../app_constants.dart';
import '../services/patient_health_provider.dart';

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
          title: const Text('Health Record'),
        ),
        body: const Center(
          child: Text(
            'No patient selected.',
            style: TextStyle(color: Colors.black45),
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(patientHealthSummaryProvider(patientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context, ref, patientId, patientName),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(context, ref, err.toString(), patientId),
        data: (summary) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(patientHealthSummaryProvider(patientId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFlags(summary),
              const SizedBox(height: 12),
              _buildProfile(summary),
              const SizedBox(height: 12),
              _buildLatestVitals(summary),
              const SizedBox(height: 12),
              _buildAllergies(summary),
              const SizedBox(height: 12),
              _buildConditions(summary),
              const SizedBox(height: 12),
              _buildMedicalHistory(summary),
              const SizedBox(height: 12),
              _buildImmunisations(summary),
              const SizedBox(height: 12),
              _buildFamilyHistory(summary),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  //  APP BAR (with Switch Patient) 
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
        patientName != null ? "$patientName's Record" : 'Health Record',
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

  //  PATIENT SWITCHER MODAL BOTTOM SHEET 
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
        builder: (context, scrollController) => Padding(
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
              const Text(
                'Switch patient',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                            Text('Could not load patients: $e'),
                          ],
                        ),
                      ),
                      data: (patients) {
                        if (patients.isEmpty) {
                          return const Center(
                            child: Text('No patients assigned to you.'),
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
                            final patientId = p['patient_id'] as String;
                            final isCurrent = patientId == currentId;

                            return Material(
                              color: isCurrent
                                  ? AppConstants.primaryColor.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Update providers – screen rebuilds automatically
                                  ref
                                          .read(
                                            selectedPatientIdProvider.notifier,
                                          )
                                          .state =
                                      patientId;
                                  ref
                                          .read(
                                            selectedPatientNameProvider
                                                .notifier,
                                          )
                                          .state =
                                      p['full_name'] as String?;
                                  Navigator.pop(context); // close bottom sheet
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
                                          child: const Text(
                                            'Current',
                                            style: TextStyle(
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

  //  FLAG BANNER 

  Widget _buildFlags(Map<String, dynamic> summary) {
    final flags = Map<String, dynamic>.from(summary['flags'] ?? {});
    final active = <_Flag>[];

    if (flags['has_severe_allergy'] == true) {
      active.add(
        _Flag(
          Icons.warning_rounded,
          'Severe allergy on record',
          Colors.red.shade700,
        ),
      );
    }
    if (flags['low_spo2'] == true) {
      active.add(
        _Flag(Icons.air, 'SpO₂ below 94% — check oxygen', Colors.red.shade700),
      );
    }
    if (flags['has_active_condition'] == true) {
      active.add(
        _Flag(
          Icons.favorite_border,
          'Active chronic condition',
          Colors.orange.shade700,
        ),
      );
    }
    if (flags['has_overdue_vaccine'] == true) {
      active.add(
        _Flag(Icons.vaccines, 'Overdue vaccine', Colors.orange.shade700),
      );
    }

    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(children: active.map((f) => _buildFlagTile(f)).toList()),
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

  //  PROFILE CARD 

  Widget _buildProfile(Map<String, dynamic> summary) {
    final p = Map<String, dynamic>.from(summary['profile'] ?? {});
    return _Card(
      title: 'Patient',
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
                  ].where((e) => e != null).join(', '),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  //  LATEST VITALS 

  Widget _buildLatestVitals(Map<String, dynamic> summary) {
    final v = summary['vitals']?['latest'] as Map<String, dynamic>?;
    if (v == null) {
      return const _Card(
        title: 'Vitals',
        icon: Icons.monitor_heart_outlined,
        child: Text(
          'No vitals recorded yet.',
          style: TextStyle(color: Colors.black45),
        ),
      );
    }

    final bp = (v['bp_systolic'] != null && v['bp_diastolic'] != null)
        ? '${v['bp_systolic']}/${v['bp_diastolic']} mmHg'
        : '—';

    final items = [
      _VitalTile('Blood pressure', bp, Icons.favorite_outline),
      _VitalTile(
        'Heart rate',
        v['heart_rate'] != null ? '${v['heart_rate']} bpm' : '—',
        Icons.monitor_heart_outlined,
      ),
      _VitalTile('SpO₂', v['spo2'] != null ? '${v['spo2']}%' : '—', Icons.air),
      _VitalTile(
        'Temperature',
        v['temperature_c'] != null ? '${v['temperature_c']}°C' : '—',
        Icons.thermostat,
      ),
      _VitalTile(
        'Weight',
        v['weight_kg'] != null ? '${v['weight_kg']} kg' : '—',
        Icons.scale_outlined,
      ),
      _VitalTile(
        'BMI',
        v['bmi'] != null ? '${v['bmi']}' : '—',
        Icons.bar_chart,
      ),
    ];

    return _Card(
      title: 'Latest vitals',
      icon: Icons.monitor_heart_outlined,
      subtitle: _fmt(v['recorded_at'] as String?),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: items.map(_buildVitalTile).toList(),
      ),
    );
  }

  Widget _buildVitalTile(_VitalTile t) => Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Row(
      children: [
        Icon(t.icon, size: 16, color: Colors.black38),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t.label,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
              Text(
                t.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  //  ALLERGIES 

  Widget _buildAllergies(Map<String, dynamic> summary) {
    final list = (summary['allergies'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return _Card(
      title: 'Allergies',
      icon: Icons.warning_amber_outlined,
      count: list.length,
      child: list.isEmpty
          ? const Text(
              'None recorded.',
              style: TextStyle(color: Colors.black45),
            )
          : Column(children: list.map(_buildAllergyTile).toList()),
    );
  }

  Widget _buildAllergyTile(Map<String, dynamic> a) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
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
      ],
    ),
  );

  //  CONDITIONS 

  Widget _buildConditions(Map<String, dynamic> summary) {
    final list = (summary['conditions'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return _Card(
      title: 'Chronic conditions',
      icon: Icons.health_and_safety_outlined,
      count: list.length,
      child: list.isEmpty
          ? const Text(
              'None recorded.',
              style: TextStyle(color: Colors.black45),
            )
          : Column(children: list.map(_buildConditionTile).toList()),
    );
  }

  Widget _buildConditionTile(Map<String, dynamic> c) => Padding(
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
      ],
    ),
  );

  //  MEDICAL HISTORY 

  Widget _buildMedicalHistory(Map<String, dynamic> summary) {
    final list = (summary['medical_history'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return _Card(
      title: 'Past consultations',
      icon: Icons.history,
      count: list.length,
      child: list.isEmpty
          ? const Text(
              'No history yet.',
              style: TextStyle(color: Colors.black45),
            )
          : Column(children: list.take(5).map(_buildHistoryTile).toList()),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> h) {
    final doctorName =
        h['doctors']?['user_profiles']?['full_name'] as String? ??
        'Unknown doctor';
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
              if (h['consultation_type'] != null)
                _TypeBadge(h['consultation_type'] as String),
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

  Widget _buildImmunisations(Map<String, dynamic> summary) {
    final list = (summary['immunisations'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return _Card(
      title: 'Immunisations',
      icon: Icons.vaccines_outlined,
      count: list.length,
      child: list.isEmpty
          ? const Text(
              'None recorded.',
              style: TextStyle(color: Colors.black45),
            )
          : Column(children: list.take(6).map(_buildImmunisationTile).toList()),
    );
  }

  Widget _buildImmunisationTile(Map<String, dynamic> imm) {
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
        ],
      ),
    );
  }

  //  FAMILY HISTORY 

  Widget _buildFamilyHistory(Map<String, dynamic> summary) {
    final list = (summary['family_history'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return _Card(
      title: 'Family history',
      icon: Icons.people_outline,
      child: Column(children: list.map(_buildFamilyTile).toList()),
    );
  }

  Widget _buildFamilyTile(Map<String, dynamic> f) => Padding(
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
      ],
    ),
  );

  //  ERROR STATE 

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    String message,
    String patientId,
  ) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
        const SizedBox(height: 12),
        Text(
          'Could not load record',
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
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  //  Helpers 

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
}

// REUSABLE UI COMPONENTS


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

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final int? count;
  final Widget child;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.count,
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
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                ),
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
    };
    const icons = {
      'video': Icons.videocam_outlined,
      'chat': Icons.chat_bubble_outline,
      'in_person': Icons.local_hospital_outlined,
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
