import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
 import 'package:healthpost_app/chat_screen.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/livekit_screen.dart';
import 'package:healthpost_app/models/notification_model.dart';
import 'package:healthpost_app/notification_screen.dart';
import 'package:healthpost_app/providers/appointment_provider.dart';
import 'package:healthpost_app/providers/notification_provider.dart';
import 'package:healthpost_app/services/appointment_reminder_seervice.dart';
import 'package:healthpost_app/services/encryption_service.dart';
import 'package:healthpost_app/services/notification_service.dart';
import 'package:healthpost_app/services/user_key_service.dart';
import 'package:healthpost_app/widgets/appointment/appointment_card.dart';
import 'package:healthpost_app/widgets/appointment/bottomsheet.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/models/doctor_appointment.dart';
import 'package:healthpost_app/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _initUserKeys();
    _tabCtrl = TabController(length: 5, vsync: this);
     _notifSub = NotificationService.instance.inAppStream.listen((n) {
      ref.read(notificationProvider.notifier).addNew(n);
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
  Future<void> _initUserKeys() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      await UserKeyService.ensureUserKeyPair(currentUserId);
    }
  }
  Future<void> _updateStatus(
    String apptId,
    Future<void> Function(String) apiCall, {
    String? snackMsg,
  }) async {
    final l = AppLocalizations.of(context)!;  

    setState(() => _processing = true);
    try {
      await ref
          .read(appointmentsProvider.notifier)
          .updateStatus(apptId, apiCall);
              await AppointmentReminderService.rescheduleAllReminders();

      Get.snackbar(
        l.updated,
        snackMsg ?? l.statusUpdated,
        backgroundColor: const Color(0xFFEAF7EF),
        colorText: const Color(0xFF1A7A4A),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        l.error,
        '${l.couldNotUpdate}: $e',
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
      title: AppLocalizations.of(context)!.confirmAppointmentQ,
      body: '${a.patientName}  •  ${a.dateTimeLabel}',
      confirmLabel: AppLocalizations.of(context)!.confirm,
      confirmColor: const Color(0xFF1565C0),
    );
    if (ok == true) {
      await _updateStatus(
        a.id,
        ApiService.confirmAppointment,
        snackMsg: AppLocalizations.of(
          context,
        )!.appointmentConfirmedFor(a.patientName),
      );
    }
  }

  Future<void> _declineAppt(DAppt a) async {
    final ok = await _confirmDialog(
      title: AppLocalizations.of(context)!.declineAppointmentQ,
      body:
          '${a.patientName}  •  ${a.dateTimeLabel}\n${AppLocalizations.of(context)!.declineWarning}',
      confirmLabel: AppLocalizations.of(context)!.decline,
      confirmColor: Colors.red,
    );
    if (ok == true) {
      await _updateStatus(
        a.id,
        ApiService.cancelAppointment,
        snackMsg: AppLocalizations.of(context)!.appointmentDeclined,
      );
    }
  }

  Future<void> _completeAppt(DAppt a) async {
    final ok = await _confirmDialog(
      title: AppLocalizations.of(context)!.markAsCompleted,
      body: AppLocalizations.of(context)!.consultationEndedWith(a.patientName),
      confirmLabel: AppLocalizations.of(context)!.complete,
      confirmColor: const Color(0xFF2E7D32),
    );
    if (ok == true) {
      await _updateStatus(
        a.id,
        ApiService.completeAppointment,
        snackMsg: AppLocalizations.of(context)!.consultationMarkedComplete,
      );
    }
  }
Future<void> _autoCompletePastAppointments(List<DAppt> confirmedAppts) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final pastConfirmed = confirmedAppts
        .where(
          (a) =>
              a.status == 'confirmed' &&
              DateTime(
                a.scheduledAt.year,
                a.scheduledAt.month,
                a.scheduledAt.day,
              ).isBefore(todayStart),
        )
        .toList();

    if (pastConfirmed.isEmpty) return;

    for (final appt in pastConfirmed) {
      try {
        await ApiService.completeAppointment(appt.id);
        debugPrint(' Auto‑completed appointment ${appt.id} (day passed)');
        if (mounted) {
          await AppointmentReminderService.rescheduleAllReminders(); 
          ref.read(appointmentsProvider.notifier).refresh();
        }
      } catch (e) {
        debugPrint(' Auto‑complete failed for ${appt.id}: $e');
      }
    }

    if (mounted) {
      ref.read(appointmentsProvider.notifier).refresh();
    }
  }
  Future<void> _noShowAppt(DAppt a) async {
    final ok = await _confirmDialog(
      title: AppLocalizations.of(context)!.markAsNoShow,
      body: AppLocalizations.of(context)!.patientDidNotJoin(a.patientName),
      confirmLabel: AppLocalizations.of(context)!.noShow,
      confirmColor: Colors.brown.shade600,
    );
    if (ok == true) {
      await _updateStatus(
        a.id,
        ApiService.noShowAppointment,
        snackMsg: AppLocalizations.of(context)!.markedAsNoShow,
      );
    }
  }

  Future<bool?> _confirmDialog({
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
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: const TextStyle(color: Colors.grey),
          ),
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
  Future<String> _ensureConversationExists(String patientId, String doctorId) async {
    final supabase = Supabase.instance.client;

    final existing = await supabase
        .from('conversations')
        .select('id')
        .eq('patient_id', patientId)
        .eq('doctor_id', doctorId)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final rows = await supabase
        .from('user_profiles')
        .select('id, public_key')
        .inFilter('id', [patientId, doctorId]);

    final Map<String, String?> rawKeys = {
      for (final r in rows) r['id'] as String : r['public_key'] as String?,
    };

    final patientKey = rawKeys[patientId];
    final doctorKey = rawKeys[doctorId];

    if (patientKey == null) {
      throw Exception(
        'Patient has not set up encryption yet. '
            'Please ask them to open the app once.',
      );
    }
    if (doctorKey == null) {
      throw Exception(
        'Doctor has not set up encryption yet. '
            'Please restart the app.',
      );
    }

    final aesKey = EncryptionService.generateAESKey();
    final aesB64 = aesKey.base64;

    final encForPatient = EncryptionService.encryptWithRSA(
      aesB64,
      EncryptionService.parsePublicKeyFromPem(patientKey),
    );
    final encForDoctor = EncryptionService.encryptWithRSA(
      aesB64,
      EncryptionService.parsePublicKeyFromPem(doctorKey),
    );

    final response = await supabase
        .from('conversations')
        .insert({
      'patient_id': patientId,
      'doctor_id': doctorId,
      'aes_key_encrypted_for_patient': encForPatient,
      'aes_key_encrypted_for_doctor': encForDoctor,
    })
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<void> _startConsultation(DAppt appt) async {
    final l = AppLocalizations.of(context)!;
    final type = appt.consultType.toLowerCase();

    if (type == 'video' || type == 'audio') {
      final isVideo = type == 'video';

      await [Permission.microphone, if (isVideo) Permission.camera].request();

      try {
        final currentUserId = Supabase.instance.client.auth.currentUser!.id;

        //  Get doctor name 
        final doctorProfile = await Supabase.instance.client
            .from('user_profiles')
            .select('full_name')
            .eq('id', currentUserId)
            .maybeSingle();
        final doctorName = doctorProfile?['full_name'] as String? ?? 'Doctor';

        // appt.patientId is already the user UUID — use directly
        final patientUserId = appt.patientId;

        if (patientUserId.isEmpty) {
          Get.snackbar(
            l.error,
            'Patient ID not found.',
            backgroundColor: const Color(0xFFFEF2F2),
            colorText: const Color(0xFFEF4444),
          );
          return;
        }

        //  Initiate LiveKit call 
        final result = await ApiService.initiateLiveKitCall(
          callerId: currentUserId,
          calleeId: patientUserId,
          appointmentId: appt.id,
          callType: isVideo ? 'video' : 'audio',
          callerName: 'Dr. $doctorName',
        );

        Get.to(
          () => LiveKitCallScreen(
            livekitUrl: 'ws://45.115.217.244:7880',
            token: result['callerToken']!,
            roomName: result['roomName']!,
            remoteUserName: appt.patientName,
            isVideo: isVideo,
            isCaller: true,
          ),
        );
      } catch (e) {
        Get.snackbar(
          l.error,
          '${l.callFailed}: $e',
          backgroundColor: const Color(0xFFFEF2F2),
          colorText: const Color(0xFFEF4444),
        );
      }
    } else if (type == 'chat' || type == 'message') {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      final patientId = appt.patientId;

      try {
        final String conversationId = await _ensureConversationExists(
          patientId,
          currentUserId,
        );
final now = DateTime.now();
        final appointmentDate = DateTime(
          appt.scheduledAt.year,
          appt.scheduledAt.month,
          appt.scheduledAt.day,
        );
        final todayDate = DateTime(now.year, now.month, now.day);
        final canMessageToday = appointmentDate == todayDate;
        Get.to(
          () => ChatScreen(
            conversationId: conversationId,
            partnerId: patientId,
            partnerName: appt.patientName,
            partnerAvatarUrl: appt.patientAvatarUrl,
            canSendMessages: canMessageToday,
          ),
        );
      } catch (e) {
        Get.snackbar('Error', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptAsync = ref.watch(appointmentsProvider);
    apptAsync.whenData((data) {
      final allConfirmed = [
        ...data.today.where((a) => a.status == 'confirmed'),
        ...data.upcoming.where((a) => a.status == 'confirmed'),
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoCompletePastAppointments(allConfirmed);
      });
    });
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
    title: Text(
      AppLocalizations.of(context)!.appointments,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    actions: [
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
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      tabs: [
        Tab(
          text: data != null && data.pending.isNotEmpty
              ? '${AppLocalizations.of(context)!.pending} (${data.pending.length})'
              : AppLocalizations.of(context)!.pending,
        ),
        Tab(
          text: data != null && data.today.isNotEmpty
              ? '${AppLocalizations.of(context)!.today} (${data.today.length})'
              : AppLocalizations.of(context)!.today,
        ),
        Tab(
          text: data != null && data.upcoming.isNotEmpty
              ? '${AppLocalizations.of(context)!.upcoming} (${data.upcoming.length})'
              : AppLocalizations.of(context)!.upcoming,
        ),
        Tab(text: AppLocalizations.of(context)!.completed),
        Tab(text: AppLocalizations.of(context)!.cancelled),
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
            onConsultTap: type == 'today' ? () => _startConsultation(a) : null,
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
    final l = AppLocalizations.of(context)!;

    final map = {
      'pending': [
        Icons.hourglass_empty_rounded,
        l.noPendingRequests,
        l.pendingAppearsHere,
      ],
      'today': [Icons.today_rounded, l.noAppointmentsToday, l.todayAppearsHere],
      'upcoming': [
        Icons.calendar_today_outlined,
        l.noUpcomingAppointments,
        l.upcomingAppearsHere,
      ],
      'completed': [
        Icons.check_circle_outline_rounded,
        l.noCompletedConsultations,
        l.completedAppearsHere,
      ],
      'cancelled': [Icons.cancel_outlined, l.noCancelledAppointments, ''],
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
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.couldNotLoadAppointments,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ref.read(appointmentsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context)!.retry),
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
