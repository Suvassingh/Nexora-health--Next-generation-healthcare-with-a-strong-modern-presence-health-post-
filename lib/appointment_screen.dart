

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/call_screen.dart';
import 'package:healthpost_app/chat_screen.dart';
import 'package:healthpost_app/models/notification_model.dart';
import 'package:healthpost_app/notification_screen.dart';
import 'package:healthpost_app/providers/appointment_provider.dart';
import 'package:healthpost_app/providers/notification_provider.dart';
import 'package:healthpost_app/services/notification_service.dart';
import 'package:healthpost_app/widgets/appointment/appointment_card.dart';
import 'package:healthpost_app/widgets/appointment/bottomsheet.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/models/doctor_appointment.dart';
import 'package:healthpost_app/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends ConsumerState<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _processing = false;
  StreamSubscription<AppNotification>? _notifSub;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    // Wire realtime in-app notifications
    _notifSub = NotificationService.instance.inAppStream.listen((n) {
      ref.read(notificationProvider.notifier).addNew(n);
      // Also refresh appointments if it's a patient booking
      if (n.type == 'new_appointment') {
        ref.read(appointmentsProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
        _notifSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(
      String apptId,
      Future<void> Function(String) apiCall, {
        String? snackMsg,
      }) async {
    setState(() => _processing = true);
    try {
      await ref
          .read(appointmentsProvider.notifier)
          .updateStatus(apptId, apiCall);
      Get.snackbar(
        'Updated',
        snackMsg ?? 'Status updated',
        backgroundColor: const Color(0xFFEAF7EF),
        colorText: const Color(0xFF1A7A4A),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
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

  Future<void> _confirmAppt(DAppt a) async {
    final ok = await _confirmDialog(
      title: 'Confirm appointment?',
      body: '${a.patientName}  •  ${a.dateTimeLabel}',
      confirmLabel: 'Confirm',
      confirmColor: const Color(0xFF1565C0),
    );
    if (ok == true) {
      await _updateStatus(
        a.id,
        ApiService.confirmAppointment,
        snackMsg: 'Appointment confirmed for ${a.patientName}',
      );
    }
  }

  Future<void> _declineAppt(DAppt a) async {
    final ok = await _confirmDialog(
      title: 'Decline appointment?',
      body: '${a.patientName}  •  ${a.dateTimeLabel}\nThis will cancel the booking.',
      confirmLabel: 'Decline',
      confirmColor: Colors.red,
    );
    if (ok == true) {
      await _updateStatus(
        a.id,
        ApiService.cancelAppointment,
        snackMsg: 'Appointment declined',
      );
    }
  }

  Future<void> _completeAppt(DAppt a) async {
    final ok = await _confirmDialog(
      title: 'Mark as completed?',
      body: 'Consultation with ${a.patientName} has ended.',
      confirmLabel: 'Complete',
      confirmColor: const Color(0xFF2E7D32),
    );
    if (ok == true) {
      await _updateStatus(
        a.id,
        ApiService.completeAppointment,
        snackMsg: 'Consultation marked complete',
      );
    }
  }

  Future<void> _noShowAppt(DAppt a) async {
    final ok = await _confirmDialog(
      title: 'Mark as no-show?',
      body: '${a.patientName} did not join the appointment.',
      confirmLabel: 'No Show',
      confirmColor: Colors.brown.shade600,
    );
    if (ok == true) {
      await _updateStatus(
        a.id,
        ApiService.noShowAppointment,
        snackMsg: 'Marked as no-show',
      );
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            body,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
              const Text('Cancel', style: TextStyle(color: Colors.grey)),
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

  Future<void> _startConsultation(DAppt appt) async {
    final type = appt.consultType.toLowerCase();
    if (type == 'video' || type == 'audio') {
      final isVideo = type == 'video';
      await [Permission.microphone, if (isVideo) Permission.camera].request();
      try {
        final result = await ApiService.initiateCall(
          calleeId: appt.patientId,
          appointmentId: appt.id,
          callType: isVideo ? 'video' : 'audio',
        );
        final callId = result['call_id'] as String;
        Get.to(
              () => CallScreen(
            callId: callId,
            remoteUserId: appt.patientId,
            remoteUserName: appt.patientName,
            isVideo: isVideo,
            isCaller: true,
          ),
        );
      } catch (e) {
        Get.snackbar('Error', 'Could not start call: $e');
      }
    } else {
      Get.to(() => ChatScreen(appt: appt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: apptAsync.when(
        // Pass counts to appbar only when data is available
        data: (data) => _buildAppBar(data),
        loading: () => _buildAppBar(null),
        error: (_, __) => _buildAppBar(null),
      ),
      body: apptAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => _buildError(e.toString()),
        data: (data) => TabBarView(
          controller: _tabCtrl,
          children: [
            _buildTab(data.pending, 'pending'),
            _buildTab(data.today, 'today'),
            _buildTab(data.upcoming, 'upcoming'),
            _buildTab(data.completed, 'completed'),
            _buildTab(data.cancelled, 'cancelled'),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppointmentsData? data) => AppBar(
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
        onPressed: () =>
            ref.read(appointmentsProvider.notifier).refresh(),
      ),
      Consumer(
        builder: (context, ref, _) {
          final unread = ref.watch(notificationProvider).unreadCount;
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () => Get.to(() => const NotificationScreen()),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      //  Original refresh button 
      IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        onPressed: () => ref.read(appointmentsProvider.notifier).refresh(),
      ),
    ],
    bottom: TabBar(
      controller: _tabCtrl,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white54,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelStyle:
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      tabs: [
        Tab(
          text: data != null && data.pending.isNotEmpty
              ? 'Pending (${data.pending.length})'
              : 'Pending',
        ),
        Tab(
          text: data != null && data.today.isNotEmpty
              ? 'Today (${data.today.length})'
              : 'Today',
        ),
        Tab(
          text: data != null && data.upcoming.isNotEmpty
              ? 'Upcoming (${data.upcoming.length})'
              : 'Upcoming',
        ),
        const Tab(text: 'Completed'),
        const Tab(text: 'Cancelled'),
      ],
    ),
  );

  Widget _buildTab(List<DAppt> list, String type) {
    if (list.isEmpty) return _buildEmpty(type);
    return RefreshIndicator(
      color: AppConstants.primaryColor,
      onRefresh: () => ref.read(appointmentsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final a = list[i];
          return ApptCard(
            appt: a,
            processing: _processing,
            onTap: () => _showDetail(a),
            onConsultTap:
            type == 'today' ? () => _startConsultation(a) : null,
            onConfirm: type == 'pending' ? () => _confirmAppt(a) : null,
            onDecline: type == 'pending' ? () => _declineAppt(a) : null,
            onComplete: (type == 'today' || type == 'upcoming')
                ? () => _completeAppt(a)
                : null,
            onNoShow: (type == 'today' || type == 'upcoming')
                ? () => _noShowAppt(a)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String type) {
    final map = {
      'pending': [
        Icons.hourglass_empty_rounded,
        'No pending requests',
        'New appointment requests will appear here',
      ],
      'today': [
        Icons.today_rounded,
        'No appointments today',
        'Your confirmed appointments for today appear here',
      ],
      'upcoming': [
        Icons.calendar_today_outlined,
        'No upcoming appointments',
        'Future confirmed appointments will appear here',
      ],
      'completed': [
        Icons.check_circle_outline_rounded,
        'No completed consultations yet',
        'Consultations you finish will appear here',
      ],
      'cancelled': [Icons.cancel_outlined, 'No cancelled appointments', ''],
    };
    final info = map[type]!;
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

  Widget _buildError(String error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.grey.shade300),
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
            error,
            style:
            TextStyle(fontSize: 11, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(appointmentsProvider.notifier).refresh(),
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