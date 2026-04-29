import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthpost_app/models/doctor_appointment.dart';
import 'package:healthpost_app/models/doctor_chat_preview.dart';
import 'package:healthpost_app/services/encryption_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatListProvider =
AsyncNotifierProvider<ChatListNotifier, List<DoctorChatPreview>>(
  ChatListNotifier.new,
);

class ChatListNotifier extends AsyncNotifier<List<DoctorChatPreview>> {
  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();

  String get _currentUserId => _supabase.auth.currentUser!.id;

  @override
  Future<List<DoctorChatPreview>> build() async {
    return _fetchChats();
  }

  Future<List<DoctorChatPreview>> _fetchChats() async {
    final conversations = await _supabase
        .from('conversations')
        .select('id, patient_id, aes_key_encrypted_for_doctor')
        .eq('doctor_id', _currentUserId);

    if ((conversations as List).isEmpty) return [];

    final patientIds = conversations
        .map((c) => c['patient_id'] as String)
        .toSet()
        .toList();

    final profiles = await _supabase
        .from('user_profiles')
        .select('id, full_name, avatar_url')
        .inFilter('id', patientIds);

    final profileMap = <String, Map<String, dynamic>>{
      for (final p in profiles as List<dynamic>)
        (p as Map<String, dynamic>)['id'] as String: p,
    };

    final privPem = await _secureStorage.read(
      key: 'rsa_private_key_$_currentUserId',
    );

    final previews = <DoctorChatPreview>[];

    for (final conv in conversations) {
      final convId = conv['id'] as String;
      final patientId = conv['patient_id'] as String;
      final profile = profileMap[patientId] ?? {};
      final patientName = profile['full_name']?.toString() ?? 'Patient';
      final avatarUrl = profile['avatar_url']?.toString();

      String? lastMessage;
      DateTime? lastMessageAt;

      try {
        if (privPem != null) {
          final privKey = EncryptionService.parsePrivateKeyFromPem(privPem);
          final aesB64 = EncryptionService.decryptWithRSA(
            conv['aes_key_encrypted_for_doctor'] as String,
            privKey,
          );
          final aesKey = encrypt.Key.fromBase64(aesB64);

          final lastMsg = await _supabase
              .from('messages')
              .select()
              .eq('conversation_id', convId)
              .eq('is_key_exchange', false)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (lastMsg != null) {
            lastMessageAt =
                DateTime.parse(lastMsg['created_at'] as String).toLocal();

            if (lastMsg['media_type'] == 'image') {
              lastMessage = '📷 Photo';
            } else if (lastMsg['media_type'] == 'video') {
              lastMessage = ' Video';
            } else if (lastMsg['encrypted_content'] != null) {
              lastMessage = EncryptionService.decryptWithAES(
                lastMsg['encrypted_content'] as String,
                aesKey,
                lastMsg['iv'] as String,
              );
            }
          }
        }
      } catch (_) {
        lastMessage = ' Encrypted message';
      }

      final appt = DAppt(
        id: convId,
        patientId: patientId,
        patientName: patientName,
        patientAvatarUrl: avatarUrl,
        scheduledAt: DateTime.now(),
        status: 'confirmed',
        consultType: 'chat',
      );

      previews.add(
        DoctorChatPreview(
          appt: appt,
          conversationId: convId,
          lastMessage: lastMessage,
          lastMessageAt: lastMessageAt,
        ),
      );
    }

    previews.sort((a, b) {
      if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });

    return previews;
  }

  // Call this to refresh — from pull-to-refresh or after returning from ChatScreen
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchChats);
  }
}