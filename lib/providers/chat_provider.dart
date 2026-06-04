
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthpost_app/models/doctor_chat_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatListProvider =
AsyncNotifierProvider<ChatListNotifier, List<DoctorChatPreview>>(
  ChatListNotifier.new,
);

class ChatListNotifier extends AsyncNotifier<List<DoctorChatPreview>> {
  final _supabase = Supabase.instance.client;
  String get _currentUserId => _supabase.auth.currentUser!.id;

  @override
  Future<List<DoctorChatPreview>> build() => _fetchChats();



  Future<List<DoctorChatPreview>> _fetchChats() async {
    final doctorRecord = await _supabase
        .from('doctors')
        .select('id')
        .eq('user_id', _currentUserId)
        .maybeSingle();
    final doctorIdInt = doctorRecord?['id'] as int?;
    if (doctorIdInt == null) {
      print(' Doctor ID not found for user $_currentUserId');
      return [];
    }

    final appointments = await _supabase
        .from('appointments')
        .select('patient_id, scheduled_at, status')
        .eq('doctor_id', doctorIdInt)
        .inFilter('status', [
          'confirmed',
          'completed',
          'no_show',
        ]);

    if (appointments.isEmpty) {
      print(' No appointments found for doctor id $doctorIdInt');
      return [];
    }

    final patientIds = appointments
        .map((a) => a['patient_id'] as String)
        .toSet()
        .toList();

    final profiles = await _supabase
        .from('user_profiles')
        .select('id, full_name, avatar_url, is_online, last_seen')
        .inFilter('id', patientIds);
    final Map<String, Map<String, dynamic>> patientMap = {
      for (final p in profiles) p['id'] as String: p,
    };

    final conversations = await _supabase
        .from('conversations')
        .select(
          'id, patient_id, last_message_preview, last_message_at, unread_count_doctor',
        )
        .eq('doctor_id', _currentUserId);
    final Map<String, Map<String, dynamic>> convMap = {};
    for (final conv in conversations) {
      convMap[conv['patient_id'] as String] = conv;
    }

final nowLocal = DateTime.now();
    final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    final Map<String, DoctorChatPreview> resultMap = {};
    for (final apt in appointments) {
      final patientId = apt['patient_id'] as String;
      final scheduledAt = DateTime.parse(apt['scheduled_at']).toUtc();
 final appointmentLocal = scheduledAt.toLocal();
      final hasToday =
          appointmentLocal.year == todayLocal.year &&
          appointmentLocal.month == todayLocal.month &&
          appointmentLocal.day == todayLocal.day;
      final profile = patientMap[patientId];
      if (profile == null) continue;

      final conversation = convMap[patientId];

      if (resultMap.containsKey(patientId)) {
        if (hasToday) {
          final existing = resultMap[patientId]!;
          resultMap[patientId] = DoctorChatPreview(
            conversationId: existing.conversationId,
            patientId: existing.patientId,
            patientName: existing.patientName,
            patientAvatarUrl: existing.patientAvatarUrl,
            lastMessage: existing.lastMessage,
            lastMessageAt: existing.lastMessageAt,
            unreadCount: existing.unreadCount,
            isOnline: existing.isOnline,
            lastSeen: existing.lastSeen,
            hasTodayAppointment: true,
          );
        }
        continue;
      }

      resultMap[patientId] = DoctorChatPreview(
        conversationId: conversation?['id'] as String? ?? '',
        patientId: patientId,
        patientName: profile['full_name'] ?? 'Patient',
        patientAvatarUrl: profile['avatar_url'] as String?,
        lastMessage: conversation?['last_message_preview'] as String?,
        lastMessageAt: conversation?['last_message_at'] != null
            ? DateTime.parse(conversation!['last_message_at'])
            : null,
        unreadCount: conversation?['unread_count_doctor'] ?? 0,
        isOnline: profile['is_online'] ?? false,
        lastSeen: profile['last_seen'] != null
            ? DateTime.parse(profile['last_seen'])
            : null,
        hasTodayAppointment: hasToday,
      );
    }

    final result = resultMap.values.toList();
    result.sort((a, b) {
      if (a.hasTodayAppointment != b.hasTodayAppointment)
        return a.hasTodayAppointment ? -1 : 1;
      if (a.lastMessageAt != null && b.lastMessageAt != null)
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      if (a.lastMessageAt != null) return -1;
      if (b.lastMessageAt != null) return 1;
      return a.patientName.compareTo(b.patientName);
    });
    return result;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchChats);
  }
}