import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/models/doctor_appointment.dart';
import 'package:healthpost_app/widgets/appointment/appointment_card.dart';
import 'package:healthpost_app/widgets/appointment/bottomsheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/app_constants.dart';







class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});
  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final _supa = Supabase.instance.client;

  late TabController _tabCtrl;

  bool _loading = true;
  bool _processing = false;
  String? _error;

  // Bucketed lists
  List<DAppt> _pending = [];
  List<DAppt> _confirmed = [];
  List<DAppt> _completed = [];
  List<DAppt> _cancelled = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _supa.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');

      final rows = await _supa
          .from('appointments')
          .select(
            'id, patient_id, scheduled_at, status, '
            'consultation_type, reason, '
            'user_profiles!appointments_patient_id_fkey(full_name, avatar_url)',
          )
          .eq('doctor_id', uid)
          .order('scheduled_at', ascending: true);

      final all = (rows as List)
          .map((e) {
            try {
              return DAppt.fromMap(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .where((a) => a != null)
          .cast<DAppt>()
          .toList();

      final now = DateTime.now();
      setState(() {
        _pending = all
            .where(
              (a) => a.isPending && (a.scheduledAt.isAfter(now) || a.isToday),
            )
            .toList();
        _confirmed = all.where((a) => a.isConfirmed).toList();
        _completed = all.where((a) => a.isCompleted).toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        _cancelled = all.where((a) => a.isCancelled).toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(
    String apptId,
    String newStatus, {
    String? snackMsg,
  }) async {
    setState(() => _processing = true);
    try {
      await _supa
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', apptId);

      Get.snackbar(
        'Updated',
        snackMsg ?? 'Status updated to $newStatus',
        backgroundColor: const Color(0xFFEAF7EF),
        colorText: const Color(0xFF1A7A4A),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
      await _load();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update: $e',
        backgroundColor: const Color(0xFFFEF2F2),
        colorText: const Color(0xFFEF4444),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Text(
        body,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  Future<void> _confirmAppt(DAppt a) async {
    final ok = await _confirm(
      title: 'Confirm appointment?',
      body: '${a.patientName}  •  ${a.dateTimeLabel}',
      confirmLabel: 'Confirm',
      confirmColor: const Color(0xFF1565C0),
    );
    if (ok == true)
      await _updateStatus(
        a.id,
        'confirmed',
        snackMsg: 'Appointment confirmed for ${a.patientName}',
      );
  }

  Future<void> _declineAppt(DAppt a) async {
    final ok = await _confirm(
      title: 'Decline appointment?',
      body:
          '${a.patientName}  •  ${a.dateTimeLabel}\nThis will cancel the booking.',
      confirmLabel: 'Decline',
      confirmColor: Colors.red,
    );
    if (ok == true)
      await _updateStatus(a.id, 'cancelled', snackMsg: 'Appointment declined');
  }

  Future<void> _completeAppt(DAppt a) async {
    final ok = await _confirm(
      title: 'Mark as completed?',
      body: 'Consultation with ${a.patientName} has ended.',
      confirmLabel: 'Complete',
      confirmColor: const Color(0xFF2E7D32),
    );
    if (ok == true)
      await _updateStatus(
        a.id,
        'completed',
        snackMsg: 'Consultation marked complete',
      );
  }

  Future<void> _noShowAppt(DAppt a) async {
    final ok = await _confirm(
      title: 'Mark as no-show?',
      body: '${a.patientName} did not join the appointment.',
      confirmLabel: 'No Show',
      confirmColor: Colors.brown.shade600,
    );
    if (ok == true)
      await _updateStatus(a.id, 'no_show', snackMsg: 'Marked as no-show');
  }

  void _showDetail(DAppt a) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DetailSheet(
      appt: a,
      onConfirm: a.isPending
          ? () {
              Navigator.pop(context);
              _confirmAppt(a);
            }
          : null,
      onDecline: a.isPending
          ? () {
              Navigator.pop(context);
              _declineAppt(a);
            }
          : null,
      onComplete: a.isConfirmed
          ? () {
              Navigator.pop(context);
              _completeAppt(a);
            }
          : null,
      onNoShow: a.isConfirmed
          ? () {
              Navigator.pop(context);
              _noShowAppt(a);
            }
          : null,
    ),
  );




  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0F4F8),
    appBar: _buildAppBar(),
    body: _loading
        ? _buildShimmer()
        : _error != null
        ? _buildError()
        : TabBarView(
            controller: _tabCtrl,
            children: [
              _buildTab(_pending, 'pending'),
              _buildTab(_confirmed, 'confirmed'),
              _buildTab(_completed, 'completed'),
              _buildTab(_cancelled, 'cancelled'),
            ],
          ),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppConstants.primaryColor,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    leading: Navigator.canPop(context)
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          )
        : null,
    title: const Text(
      'Appointments',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        onPressed: _load,
      ),
    ],
    bottom: TabBar(
      controller: _tabCtrl,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white54,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      tabs: [
        Tab(
          text: 'Pending${_pending.isNotEmpty ? " (${_pending.length})" : ""}',
        ),
        Tab(
          text:
              'Confirmed${_confirmed.isNotEmpty ? " (${_confirmed.length})" : ""}',
        ),
        Tab(text: 'Done'),
        Tab(text: 'Cancelled'),
      ],
    ),
  );

  Widget _buildTab(List<DAppt> list, String type) {
    if (list.isEmpty) return _buildEmpty(type);
    return RefreshIndicator(
      color: AppConstants.primaryColor,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final a = list[i];
          return ApptCard(
            appt: a,
            processing: _processing,
            onTap: () => _showDetail(a),
            // Pending tab — Confirm + Decline
            onConfirm: type == 'pending' ? () => _confirmAppt(a) : null,
            onDecline: type == 'pending' ? () => _declineAppt(a) : null,
            // Confirmed tab — Complete + No Show
            onComplete: type == 'confirmed' ? () => _completeAppt(a) : null,
            onNoShow: type == 'confirmed' ? () => _noShowAppt(a) : null,
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String type) {
    final Map<String, List<dynamic>> map = {
      'pending': [
        Icons.hourglass_empty_rounded,
        'No pending requests',
        'New appointment requests will appear here',
      ],
      'confirmed': [
        Icons.event_available_outlined,
        'No confirmed appointments',
        'Confirmed appointments will appear here',
      ],
      'completed': [
        Icons.check_circle_outline_rounded,
        'No completed consultations yet',
        'Consultations you finish will appear here',
      ],
      'cancelled': [Icons.cancel_outlined, 'No cancelled appointments', ''],
    };
    final info = map[type] ?? map['pending']!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info[0] as IconData, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          Text(
            info[1] as String,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          if ((info[2] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              info[2] as String,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 170,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load appointments',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? '',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


   





class PatientAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  const PatientAvatar({required this.name, this.url, required this.size});

  String get _initials {
    final pts = name.trim().split(' ');
    if (pts.length >= 2) return '${pts[0][0]}${pts[1][0]}'.toUpperCase();
    return pts.isNotEmpty && pts[0].isNotEmpty ? pts[0][0].toUpperCase() : 'P';
  }

  @override
  Widget build(BuildContext context) {
    final r = size / 2;
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: r,
        backgroundImage: NetworkImage(url!),
        backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
      );
    }
    return CircleAvatar(
      radius: r,
      backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
      child: Text(
        _initials,
        style: TextStyle(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: r * 0.65,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class Rows extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const Rows(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppConstants.primaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    ),
  );
}

class ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            backgroundColor: color.withOpacity(0.06),
            side: BorderSide(color: color.withOpacity(0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: shape,
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: shape,
        ),
      ),
    );
  }
}
