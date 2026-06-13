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
// ========== HELPER FUNCTIONS (same as patient app) ==========

IconData consultTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'video':
      return Icons.videocam_rounded;
    case 'audio':
    case 'phone':
      return Icons.call_rounded;
    case 'chat':
    case 'message':
      return Icons.chat_bubble_rounded;
    default:
      return Icons.local_hospital_rounded;
  }
}

String consultTypeLabel(String type, BuildContext context) {
  final l = AppLocalizations.of(context)!;
  switch (type.toLowerCase()) {
    case 'video':
      return l.video;
    case 'audio':
    case 'phone':
      return l.audio;
    case 'chat':
    case 'message':
      return l.chat;
    default:
      return l.physical;
  }
}

Color consultTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'video':
      return const Color(0xFF6C5CE7);
    case 'audio':
    case 'phone':
      return const Color(0xFF00B894);
    case 'chat':
    case 'message':
      return const Color(0xFF0984E3);
    default:
      return const Color(0xFFE17055);
  }
}
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



  void _showDetailSheet(DAppt a) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DoctorDetailSheet(
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
      onConsultTap: a.isToday && !a.isPending
          ? () {
              Navigator.pop(context);
              _startConsultation(a);
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
    child: _BadgeTab(
      label: AppLocalizations.of(context)!.pending,
      count: data?.pending.length ?? 0,
      badgeColor: const Color(0xFFF57F17),
      showDot: (data?.pending.length ?? 0) > 0,
    ),
  ),
  Tab(
    child: _BadgeTab(
      label: AppLocalizations.of(context)!.today,
      count: data?.today.length ?? 0,
      badgeColor: AppConstants.primaryColor,
      showDot: (data?.today.length ?? 0) > 0,
    ),
  ),
  Tab(
    child: _BadgeTab(
      label: AppLocalizations.of(context)!.upcoming,
      count: data?.upcoming.length ?? 0,
      badgeColor: const Color(0xFF4CAF50),
      showDot: (data?.upcoming.length ?? 0) > 0,
    ),
  ),
  Tab(
    child: _BadgeTab(
      label: AppLocalizations.of(context)!.completed,
      count: data?.completed.length ?? 0,
      badgeColor: const Color(0xFF2196F3),
      showDot: (data?.completed.length ?? 0) > 0,
    ),
  ),
  Tab(
    child: _BadgeTab(
      label: AppLocalizations.of(context)!.cancelled,
      count: data?.cancelled.length ?? 0,
      badgeColor: const Color(0xFFF44336),
      showDot: (data?.cancelled.length ?? 0) > 0,
    ),
  ),
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
          return DoctorApptCard(
            appt: a,
            processing: _processing,
            onTap: () => _showDetailSheet(a),
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
class DoctorApptCard extends StatelessWidget {
  final DAppt appt;
  final bool processing;
  final VoidCallback? onTap;
  final VoidCallback? onConsultTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onNoShow;

  const DoctorApptCard({
    super.key,
    required this.appt,
    required this.processing,
    this.onTap,
    this.onConsultTap,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
    this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = appt.consultIconColor;
    final typeIcon = appt.consultIcon;

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: appt.isPending
            ? const Border(left: BorderSide(color: Color(0xFFF57F17), width: 4))
            : appt.isToday && !appt.isPending
            ? Border(
                left: BorderSide(color: AppConstants.primaryColor, width: 4),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (appt.isPending)
            _buildBanner(
              icon: Icons.hourglass_empty_rounded,
              color: const Color(0xFFF57F17),
              bgColor: const Color(0xFFFFF8E1),
              text: AppLocalizations.of(context)!.awaitingYourConfirmation,
            ),
          if (appt.isToday && !appt.isPending)
            _buildBanner(
              icon: Icons.today_rounded,
              color: AppConstants.primaryColor,
              bgColor: AppConstants.primaryColor.withOpacity(0.08),
              text: AppLocalizations.of(context)!.todaysAppointment,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _Avatar(
                      name: appt.patientName,
                      url: appt.patientAvatarUrl,
                      size: 50,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: typeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(typeIcon, size: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.patientName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: Color(0xFFB71C1C),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                appt.dateTimeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFB71C1C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(typeIcon, size: 12, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  appt.consultLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: typeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (appt.patientNotes != null &&
                          appt.patientNotes!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          appt.patientNotes!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: appt.statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appt.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasButtons()) ...[
            const Divider(height: 1, thickness: 0.5, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _buildActionButtons(context),
            ),
          ],
        ],
      ),
    );
    if (onTap != null) card = GestureDetector(onTap: onTap, child: card);
    return card;
  }

  bool _hasButtons() =>
      (appt.isPending && (onConfirm != null || onDecline != null)) ||
      (appt.isToday &&
          (onConsultTap != null || onComplete != null || onNoShow != null)) ||
      ((appt.isConfirmed && !appt.isToday) &&
          (onComplete != null || onNoShow != null));

  Widget _buildActionButtons(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (appt.isPending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: processing ? null : onDecline,
              icon: const Icon(Icons.close, size: 17),
              label: Text(l.decline),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                backgroundColor: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: processing ? null : onConfirm,
              icon: const Icon(Icons.check, size: 17),
              label: Text(l.confirm),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }
    final isToday = appt.isToday && !appt.isPending;
    return Column(
      children: [
        if (isToday && onConsultTap != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: processing ? null : onConsultTap,
              icon: Icon(appt.consultIcon, size: 17),
              label: Text(_joinLabel(appt.consultType, context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: appt.consultIconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        if (isToday &&
            onConsultTap != null &&
            (onComplete != null || onNoShow != null))
          const SizedBox(height: 8),
        Row(
          children: [
            if (onComplete != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: processing ? null : onComplete,
                  icon: const Icon(Icons.check_circle_outline, size: 17),
                  label: Text(l.complete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFFA5D6A7)),
                    backgroundColor: const Color(0xFFE8F5E9),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (onComplete != null && onNoShow != null)
              const SizedBox(width: 10),
            if (onNoShow != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: processing ? null : onNoShow,
                  icon: const Icon(Icons.person_off_outlined, size: 17),
                  label: Text(l.noShow),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.brown.shade600,
                    side: BorderSide(color: Colors.brown.shade200),
                    backgroundColor: Colors.brown.shade50,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _joinLabel(String type, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (type.toLowerCase()) {
      case 'video':
        return l.joinVideoCall;
      case 'audio':
        return l.joinAudioCall;
      case 'chat':
        return l.startChat;
      default:
        return l.viewDetails;
    }
  }
}


class DoctorDetailSheet extends StatelessWidget {
  final DAppt appt;
  final VoidCallback? onConfirm, onDecline, onComplete, onNoShow, onConsultTap;
  const DoctorDetailSheet({
    super.key,
    required this.appt,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
    this.onNoShow,
    this.onConsultTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typeColor = appt.consultIconColor;
    final typeIcon = appt.consultIcon;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: typeColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(typeIcon, size: 18, color: typeColor),
                  const SizedBox(width: 10),
                  Text(
                    appt.consultLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: typeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _consultDescription(appt.consultType, context),
                    style: TextStyle(
                      fontSize: 12,
                      color: typeColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (appt.isPending)
              _buildStatusBanner(
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFFF57F17),
                bgColor: const Color(0xFFFFF8E1),
                text: l.appointmentPendingConfirmation,
              ),
            if (appt.isToday && !appt.isPending)
              _buildStatusBanner(
                icon: Icons.today_rounded,
                color: AppConstants.primaryColor,
                bgColor: AppConstants.primaryColor.withOpacity(0.08),
                text: l.todaysAppointment,
              ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          _Avatar(
                            name: appt.patientName,
                            url: appt.patientAvatarUrl,
                            size: 56,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                typeIcon,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt.patientName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: appt.statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          appt.statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SheetRow(
                    icon: Icons.calendar_today_rounded,
                    label: l.date,
                    value: appt.dateLabel,
                  ),
                  _SheetRow(
                    icon: Icons.access_time_rounded,
                    label: l.time,
                    value: appt.timeLabel,
                  ),
                  _SheetRow(
                    icon: typeIcon,
                    label: l.consultationType,
                    value: appt.consultLabel,
                  ),
                  if (appt.patientNotes != null &&
                      appt.patientNotes!.isNotEmpty)
                    _SheetRow(
                      icon: Icons.notes_rounded,
                      label: l.reason,
                      value: appt.patientNotes!,
                    ),
                  const SizedBox(height: 24),
                  if (appt.isPending &&
                      (onConfirm != null || onDecline != null))
                    Row(
                      children: [
                        if (onDecline != null)
                          Expanded(child: _buildDeclineButton(context)),
                        if (onConfirm != null && onDecline != null)
                          const SizedBox(width: 10),
                        if (onConfirm != null)
                          Expanded(child: _buildConfirmButton(context)),
                      ],
                    ),
                  if (appt.isToday && !appt.isPending && onConsultTap != null)
                    _buildConsultButton(context),
                  if ((appt.isToday || (appt.isConfirmed && !appt.isToday)) &&
                      (onComplete != null || onNoShow != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          if (onComplete != null)
                            Expanded(child: _buildCompleteButton(context)),
                          if (onComplete != null && onNoShow != null)
                            const SizedBox(width: 10),
                          if (onNoShow != null)
                            Expanded(child: _buildNoShowButton(context)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) => ElevatedButton.icon(
    onPressed: onConfirm,
    icon: const Icon(Icons.check, size: 18),
    label: Text(AppLocalizations.of(context)!.confirm),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
  );

  Widget _buildDeclineButton(BuildContext context) => OutlinedButton.icon(
    onPressed: onDecline,
    icon: const Icon(Icons.close, size: 18),
    label: Text(AppLocalizations.of(context)!.decline),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.red.shade600,
      backgroundColor: Colors.red.shade50,
      side: BorderSide(color: Colors.red.shade300),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _buildConsultButton(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onConsultTap,
      icon: Icon(appt.consultIcon, size: 18),
      label: Text(_joinLabel(appt.consultType, context)),
      style: ElevatedButton.styleFrom(
        backgroundColor: appt.consultIconColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
  );

  Widget _buildCompleteButton(BuildContext context) => OutlinedButton.icon(
    onPressed: onComplete,
    icon: const Icon(Icons.check_circle_outline, size: 18),
    label: Text(AppLocalizations.of(context)!.complete),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF2E7D32),
      side: const BorderSide(color: Color(0xFFA5D6A7)),
      backgroundColor: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _buildNoShowButton(BuildContext context) => OutlinedButton.icon(
    onPressed: onNoShow,
    icon: const Icon(Icons.person_off_outlined, size: 18),
    label: Text(AppLocalizations.of(context)!.noShow),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.brown.shade600,
      side: BorderSide(color: Colors.brown.shade200),
      backgroundColor: Colors.brown.shade50,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  String _consultDescription(String type, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (type.toLowerCase()) {
      case 'video':
        return l.videoConsultation;
      case 'audio':
        return l.phoneConsultation;
      case 'chat':
        return l.messageConsultation;
      default:
        return l.physicalVisit;
    }
  }

  String _joinLabel(String type, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (type.toLowerCase()) {
      case 'video':
        return l.joinVideoCall;
      case 'audio':
        return l.joinAudioCall;
      case 'chat':
        return l.startChat;
      default:
        return l.viewDetails;
    }
  }
}
class _BadgeTab extends StatelessWidget {
  final String label;
  final int count;
  final Color badgeColor;
  final bool showDot;
  const _BadgeTab({
    required this.label,
    required this.count,
    required this.badgeColor,
    required this.showDot,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label),
      if (showDot) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ],
  );
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  const _Avatar({required this.name, this.url, required this.size});

  String get _initials {
    final pts = name.trim().split(' ');
    if (pts.length >= 2) return '${pts[0][0]}${pts[1][0]}'.toUpperCase();
    return pts.isNotEmpty && pts[0].isNotEmpty ? pts[0][0].toUpperCase() : 'P';
  }

  @override
  Widget build(BuildContext context) {
    final r = size / 2;
    if (url != null && url!.isNotEmpty)
      return CircleAvatar(radius: r, backgroundImage: NetworkImage(url!));
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
