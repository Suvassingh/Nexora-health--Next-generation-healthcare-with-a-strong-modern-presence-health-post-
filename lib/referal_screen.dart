

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthpost_app/providers/referal_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_constants.dart';


class ReferralListSection extends ConsumerWidget {
  final String patientId;
  const ReferralListSection({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patientReferralsProvider(patientId));

    return _Card(
      title: 'Referrals',
      icon: Icons.send_outlined,
      count: async.value?.length,
      trailing: _AddButton(
        label: 'New Referral',
        onTap: () => _openForm(context, ref, patientId),
      ),
      child: async.when(
        loading: () => const SizedBox(
          height: 36,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const Text(
          'Could not load referrals.',
          style: TextStyle(color: Colors.black45),
        ),
        data: (list) => list.isEmpty
            ? const Text(
                'No referrals yet.',
                style: TextStyle(color: Colors.black45),
              )
            : Column(
                children: list
                    .take(3)
                    .map((r) => _ReferralTile(referral: r))
                    .toList(),
              ),
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, String patientId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReferralFormScreen(patientId: patientId),
      ),
    );
  }
}

//  REFERRAL TILE  

class _ReferralTile extends StatelessWidget {
  final Map<String, dynamic> referral;
  const _ReferralTile({required this.referral});

  @override
  Widget build(BuildContext context) {
    final urgency = referral['urgency'] as String? ?? 'routine';
    final status = referral['status'] as String? ?? 'pending';
    final pdfUrl = referral['pdf_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: ref no + urgency badge
          Row(
            children: [
              Expanded(
                child: Text(
                  referral['ref_no'] as String? ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              _UrgencyBadge(urgency),
              const SizedBox(width: 6),
              _StatusBadge(status),
            ],
          ),
          const SizedBox(height: 6),
          // diagnosis
          Text(
            referral['diagnosis'] as String? ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          // to facility
          if (referral['to_facility'] != null)
            Row(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  size: 12,
                  color: Colors.black38,
                ),
                const SizedBox(width: 4),
                Text(
                  '→ ${referral['to_facility']['name']}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(referral['created_at'] as String?),
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
              if (pdfUrl != null)
                GestureDetector(
                  onTap: () => _openPdf(context, pdfUrl), 
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 14,
                        color: Colors.indigo.shade600,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'View PDF',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.indigo.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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

Future<void> _openPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open PDF link.')));
    }
  }
}

//  FULL-PAGE FORM

class ReferralFormScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? patientName; 
  const ReferralFormScreen({
    super.key,
    required this.patientId,
    this.patientName,
  });
  @override
  ConsumerState<ReferralFormScreen> createState() => _ReferralFormScreenState();
}

class _ReferralFormScreenState extends ConsumerState<ReferralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // controllers
  late final TextEditingController _patientName;
  late final TextEditingController _patientAge;
  late final TextEditingController _patientContact;
  late final TextEditingController _diagnosis;
  late final TextEditingController _reason;
  late final TextEditingController _investigations;
  late final TextEditingController _treatment;

  String _sex = 'Male';
  String _urgency = 'routine';

  // facility selections
  Map<String, dynamic>? _fromFacility;
  Map<String, dynamic>? _toFacility;

  @override
  void initState() {
    super.initState();
    _patientName = TextEditingController(text: widget.patientName ?? '');
    _patientAge = TextEditingController();
    _patientContact = TextEditingController();
    _diagnosis = TextEditingController();
    _reason = TextEditingController();
    _investigations = TextEditingController();
    _treatment = TextEditingController();
  }

  @override
  void dispose() {
    _patientName.dispose();
    _patientAge.dispose();
    _patientContact.dispose();
    _diagnosis.dispose();
    _reason.dispose();
    _investigations.dispose();
    _treatment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromFacility == null || _toFacility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select both referring and receiving facilities.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_fromFacility!['id'] == _toFacility!['id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From and To facilities cannot be the same.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = {
      'patient_id': widget.patientId,
      'patient_name': _patientName.text.trim(),
      'patient_age': int.tryParse(_patientAge.text.trim()),
      'patient_sex': _sex,
      if (_patientContact.text.isNotEmpty)
        'patient_contact': _patientContact.text.trim(),
      'diagnosis': _diagnosis.text.trim(),
      'reason_for_referral': _reason.text.trim(),
      'urgency': _urgency,
      'from_facility_id': _fromFacility!['id'],
      'to_facility_id': _toFacility!['id'],
      if (_investigations.text.isNotEmpty)
        'investigations_done': _investigations.text.trim(),
      if (_treatment.text.isNotEmpty) 'treatment_given': _treatment.text.trim(),
    };

    try {
      final result = await ref.read(createReferralProvider)(payload);
      // Invalidate so the list card refreshes
      ref.invalidate(patientReferralsProvider(widget.patientId));

      if (!mounted) return;
      setState(() => _saving = false);

      // Show success + PDF link
      _showSuccessSheet(
        context,
        refNo: result['ref_no'] as String,
        pdfUrl: result['pdf_url'] as String?,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showSuccessSheet(
    BuildContext context, {
    required String refNo,
    String? pdfUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Referral Created',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              refNo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            if (pdfUrl != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(pdfUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Open Referral Letter (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: BorderSide(color: AppConstants.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: facilitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(facilitiesProvider),
        ),
        data: (allFacilities) {
          final fromFacilities = allFacilities;
          final toFacilities = allFacilities
              .where((f) => f['type'] != 'healthpost')
              .toList();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Patient Information 
                _SectionHeader(
                  label: 'Patient Information',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 8),
                _OutlinedCard(
                  child: Column(
                    children: [
                      _FormField(
                        controller: _patientName,
                        label: 'Full Name *',
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              controller: _patientAge,
                              label: 'Age *',
                              keyboardType: TextInputType.number,
                              validator: _required,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InlineDropdown<String>(
                              label: 'Sex',
                              value: _sex,
                              items: const ['Male', 'Female', 'Other'],
                              labelOf: (s) => s,
                              onChanged: (v) => setState(() => _sex = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: _patientContact,
                        label: 'Contact Number',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Clinical Details 
                _SectionHeader(
                  label: 'Clinical Details',
                  icon: Icons.medical_information_outlined,
                ),
                const SizedBox(height: 8),
                _OutlinedCard(
                  child: Column(
                    children: [
                      _FormField(
                        controller: _diagnosis,
                        label: 'Diagnosis *',
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: _reason,
                        label: 'Reason for Referral *',
                        maxLines: 3,
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: _investigations,
                        label: 'Investigations Done',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: _treatment,
                        label: 'Treatment Given',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _InlineDropdown<String>(
                        label: 'Urgency',
                        value: _urgency,
                        items: const ['routine', 'urgent', 'emergency'],
                        labelOf: (s) => s[0].toUpperCase() + s.substring(1),
                        onChanged: (v) => setState(() => _urgency = v!),
                        itemColor: (s) {
                          switch (s) {
                            case 'emergency':
                              return Colors.red.shade600;
                            case 'urgent':
                              return Colors.orange.shade700;
                            default:
                              return Colors.green.shade600;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Facilities
                _SectionHeader(
                  label: 'Facilities',
                  icon: Icons.local_hospital_outlined,
                ),
                const SizedBox(height: 8),
                _OutlinedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FacilityPicker(
                        label: 'Referring Facility (From) *',
                        selected: _fromFacility,
                        facilities: fromFacilities,
                        onSelected: (f) => setState(() => _fromFacility = f),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                      _FacilityPicker(
                        label: 'Receiving Facility (To) *',
                        selected: _toFacility,
                        facilities: toFacilities,
                        onSelected: (f) => setState(() => _toFacility = f),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text(
                    'Create Referral & Generate Letter',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      title: const Text(
        'New Referral',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

//  FACILITY PICKER WIDGET

class _FacilityPicker extends StatelessWidget {
  final String label;
  final Map<String, dynamic>? selected;
  final List<Map<String, dynamic>> facilities;
  final void Function(Map<String, dynamic>) onSelected;

  const _FacilityPicker({
    required this.label,
    required this.selected,
    required this.facilities,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected?['name'] as String? ?? 'Tap to select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: selected != null ? Colors.black87 : Colors.black38,
                    ),
                  ),
                  if (selected != null &&
                      (selected!['district'] != null ||
                          selected!['type'] != null))
                    Text(
                      [
                        selected!['type'],
                        selected!['district'],
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FacilityPickerSheet(
        title: label,
        facilities: facilities,
        onSelected: (f) {
          onSelected(f);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FacilityPickerSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> facilities;
  final void Function(Map<String, dynamic>) onSelected;

  const _FacilityPickerSheet({
    required this.title,
    required this.facilities,
    required this.onSelected,
  });

  @override
  State<_FacilityPickerSheet> createState() => _FacilityPickerSheetState();
}

class _FacilityPickerSheetState extends State<_FacilityPickerSheet> {
  String _query = '';

  List<Map<String, dynamic>> get _filtered => widget.facilities
      .where(
        (f) =>
            (f['name'] as String? ?? '').toLowerCase().contains(
              _query.toLowerCase(),
            ) ||
            (f['district'] as String? ?? '').toLowerCase().contains(
              _query.toLowerCase(),
            ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // handle
          Container(
            margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search facilities…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No facilities found',
                      style: TextStyle(color: Colors.black45),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final f = _filtered[i];
                      final type = f['type'] as String? ?? '';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: _typeColor(type).withOpacity(.12),
                          child: Icon(
                            _typeIcon(type),
                            size: 16,
                            color: _typeColor(type),
                          ),
                        ),
                        title: Text(
                          f['name'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          [
                            type,
                            f['district'],
                            f['province'],
                          ].whereType<String>().join(' · '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                        onTap: () => widget.onSelected(f),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'zonal':
        return Colors.purple;
      case 'district':
        return Colors.blue;
      case 'primary':
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'zonal':
      case 'district':
        return Icons.local_hospital;
      case 'primary':
        return Icons.medical_services_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }
}


//  BADGE WIDGETS


class _UrgencyBadge extends StatelessWidget {
  final String urgency;
  const _UrgencyBadge(this.urgency);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (urgency) {
      case 'emergency':
        color = Colors.red.shade700;
        break;
      case 'urgent':
        color = Colors.orange.shade700;
        break;
      default:
        color = Colors.green.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        urgency.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = status == 'completed'
        ? Colors.green.shade600
        : status == 'received'
        ? Colors.blue.shade600
        : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

//  REUSABLE LAYOUT HELPERS  (local to this file)

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  final Widget child;
  const _OutlinedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: child,
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _InlineDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final void Function(T?) onChanged;
  final Color Function(T)? itemColor;

  const _InlineDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    labelOf(i),
                    style: TextStyle(
                      color: itemColor?.call(i),
                      fontWeight: itemColor != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 12, color: Colors.indigo.shade700),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.indigo.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;
  final Widget child;
  final Widget? trailing;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
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
