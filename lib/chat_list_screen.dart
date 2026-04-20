import 'dart:async';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/chat_screen.dart';
import 'package:healthpost_app/models/doctor_appointment.dart';
import 'package:healthpost_app/models/doctor_chat_preview.dart';
import 'package:healthpost_app/services/encryption_service.dart';
import 'package:healthpost_app/widgets/doctor_chat_title.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorChatListScreen extends StatefulWidget {
  const DoctorChatListScreen({super.key});

  @override
  State<DoctorChatListScreen> createState() => _DoctorChatListScreenState();
}

class _DoctorChatListScreenState extends State<DoctorChatListScreen> {
  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();

  List<DoctorChatPreview> _chats = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _subscribeToNewMessages();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  //  LOAD 

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch all conversations where this doctor is involved
      final conversations = await _supabase
          .from('conversations')
          .select('id, patient_id, aes_key_encrypted_for_doctor')
          .eq('doctor_id', _currentUserId);

      if (conversations.isEmpty) {
        setState(() {
          _chats = [];
          _loading = false;
        });
        return;
      }

      // 2. Fetch patient profiles
      final patientIds = (conversations as List)
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

      // 3. Load private key once
      final privPem = await _secureStorage.read(
        key: 'rsa_private_key_$_currentUserId',
      );

      // 4. Build previews
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
              lastMessageAt = DateTime.parse(
                lastMsg['created_at'] as String,
              ).toLocal();

              if (lastMsg['media_type'] == 'image') {
                lastMessage = ' Photo';
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

        // Build a DAppt for navigation
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

      // Sort by most recent message
      previews.sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      setState(() => _chats = previews);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load chats: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  //  REALTIME 

  void _subscribeToNewMessages() {
    _channel = _supabase
        .channel('chat_list_doctor_$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => _loadChats(),
        )
        .subscribe();
  }

  //  BUILD 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text(
          'Patient Messages',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadChats,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _chats.length,
                itemBuilder: (_, i) => DoctorChatTile(
                  preview: _chats[i],
                  currentUserId: _currentUserId,
                  onTap: () async {
                    await Get.to(
                      () => ChatScreen(appt: _chats[i].appt),
                    );
                    _loadChats();
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_chat_unread_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No patient chats yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patients with chat appointments\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}





