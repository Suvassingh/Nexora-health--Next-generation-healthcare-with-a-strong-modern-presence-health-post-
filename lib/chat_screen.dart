 import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/app_constants.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:healthpost_app/services/encryption_service.dart';
import 'package:healthpost_app/services/key_manager_service.dart';
import 'package:healthpost_app/services/media_download_service.dart';
import 'package:healthpost_app/services/presence_service.dart';
import 'package:healthpost_app/widgets/media_preview_dilog.dart';
import 'package:healthpost_app/widgets/message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String partnerId;          
  final String partnerName;        
  final String? partnerAvatarUrl;
  final bool canSendMessages;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    required this.canSendMessages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  List<Map<String, dynamic>> _messages = [];
  String? _conversationId;
  encrypt.Key? _aesKey;
  bool _loading = true;
  bool _sending = false;
  RealtimeChannel? _channel;
  RealtimeChannel? _typingChannel;
  String? _currentUserPrivateKeyPem;

  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;
  DateTime? _oldestTimestamp;

  bool _partnerTyping = false;
  Timer? _typingTimer;
  bool _iAmTyping = false;

  final Map<String, List<Map<String, dynamic>>> _reactions = {};

  String get _currentUserId => _supabase.auth.currentUser!.id;
  String get _partnerId => widget.partnerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _conversationId = widget.conversationId;
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _typingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PresenceService.startHeartbeat();
    } else if (state == AppLifecycleState.paused) {
      PresenceService.stopHeartbeat();
      PresenceService.setOffline();
    }
  }
// In _ChatScreenState

  Future<void> _pickAndSendImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    for (final img in images) {
      _showMediaPreview(File(img.path), 'image');
    }
  }

  Future<void> _pickAndSendVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      _showMediaPreview(File(file.path), 'video');
    }
  }

  void _showMediaPreview(File file, String mediaType) {
    showDialog(
      context: context,
      builder: (_) => MediaPreviewDialog(
        file: file,
        mediaType: mediaType,
        onConfirm: () => _uploadAndSendMedia(file, mediaType),
      ),
    );
  }
Future<void> _initializeChat() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      print('1. Start init');
      if (_conversationId == null || _conversationId!.isEmpty) {
        print('2. No conversation ID, creating...');
        await _ensureConversationExists();
        print('3. Conversation ID now: $_conversationId');
      }
      print('4. Ensuring user key pair...');
      await _ensureUserKeyPair();
      print('5. Fetching AES key...');
      await _fetchAndDecryptAESKey();
      print('6. Loading messages...');
      await _loadMessages(initial: true);
      print('7. Setting up realtime...');
      _setupRealtime();
      _setupTypingIndicator();
      await _markMessagesRead();
      print('8. Init complete');
    } catch (e) {
      print('Error in _initializeChat: $e');
      if (mounted) {
        Get.snackbar('Error', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  //  Key management 
  // Future<void> _ensureUserKeyPair() async {
  //   final profile = await _supabase
  //       .from('user_profiles')
  //       .select('public_key')
  //       .eq('id', _currentUserId)
  //       .maybeSingle();
  //   final stored = await _secureStorage.read(key: 'private_key_$_currentUserId');
  //   final privIsOld = stored != null && !_isValidKeyFormat(stored);
  //   final pubIsOld = profile != null &&
  //       profile['public_key'] != null &&
  //       !_isValidKeyFormat(profile['public_key'] as String);
  //   if (stored == null ||
  //       profile == null ||
  //       profile['public_key'] == null ||
  //       privIsOld ||
  //       pubIsOld) {
  //     await _generateAndSaveKeyPair();
  //   } else {
  //     _currentUserPrivateKeyPem = stored;
  //   }
  // }


  Future<void> _ensureUserKeyPair() async {
    // KeyManagerService already ran at login; just retrieve what it stored.
    final privKey = await KeyManagerService.getPrivateKey();
    if (privKey == null) {
      // Fallback: re-run full key setup (cold install, cleared storage, etc.)
      await KeyManagerService.ensureKeyPair();
    }
    // Read PEM from the canonical key name
    _currentUserPrivateKeyPem = await _secureStorage.read(
      key: 'private_key_$_currentUserId',
    );
    if (_currentUserPrivateKeyPem == null) {
      throw Exception('Encryption key unavailable. Please restart the app.');
    }
  }

  bool _isValidKeyFormat(String pem) {
    try {
      final bytes = base64Decode(pem);
      final decoded = utf8.decode(bytes);
      if (decoded.startsWith('{')) {
        final map = jsonDecode(decoded) as Map;
        return map.containsKey('n') && map.containsKey('e');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _generateAndSaveKeyPair() async {
    final kp = EncryptionService.generateRSAKeyPair();
    final pub = EncryptionService.publicKeyToPem(kp.publicKey);
    final priv = EncryptionService.privateKeyToPem(kp.privateKey);
    await _secureStorage.write(key: 'private_key_$_currentUserId', value: priv);
    await _supabase.from('user_profiles').update({'public_key': pub}).eq('id', _currentUserId);
    _currentUserPrivateKeyPem = priv;
  }


  Future<void> _fetchAndDecryptAESKey() async {
    if (_conversationId == null || _conversationId!.isEmpty) {
      throw Exception('No conversation ID available');
    }

    final conv = await _supabase
        .from('conversations')
        .select('aes_key')
        .eq('id', _conversationId!)
        .maybeSingle();

    final aesB64 = conv?['aes_key'] as String?;
    if (aesB64 == null) {
      throw Exception('AES key not found. Please start a new conversation.');
    }

    _aesKey = encrypt.Key.fromBase64(aesB64);
  }

// Replace _ensureConversationExists
  Future<void> _ensureConversationExists() async {
    if (_conversationId != null && _conversationId!.isNotEmpty) return;

    final existing = await _supabase
        .from('conversations')
        .select('id')
        .eq('doctor_id', _currentUserId)
        .eq('patient_id', widget.partnerId)
        .maybeSingle();

    if (existing != null) {
      _conversationId = existing['id'] as String;
      return;
    }

    // Generate plain AES key — stored server-side, protected by RLS
    final aesKey = EncryptionService.generateAESKey();
    final aesB64 = aesKey.base64;

    try {
      final newConv = await _supabase
          .from('conversations')
          .insert({
        'patient_id': widget.partnerId,
        'doctor_id': _currentUserId,
        'aes_key': aesB64,
      })
          .select('id')
          .single();
      _conversationId = newConv['id'] as String;
    } catch (e) {
      if (e.toString().contains('23505')) {
        // Race condition — other party created it first
        final retry = await _supabase
            .from('conversations')
            .select('id')
            .eq('doctor_id', _currentUserId)
            .eq('patient_id', widget.partnerId)
            .maybeSingle();
        if (retry != null) {
          _conversationId = retry['id'] as String;
          return;
        }
      }
      rethrow;
    }
  }
// Future<void> _fetchAndDecryptAESKey() async {
//     if (_conversationId == null || _conversationId!.isEmpty) {
//       throw Exception('No conversation ID available');
//     }
//     if (_currentUserPrivateKeyPem == null) {
//       throw Exception(
//         'Your encryption key is missing. Please restart the app.',
//       );
//     }
//
//     final conv = await _supabase
//         .from('conversations')
//         .select('aes_key')
//         .eq('id', _conversationId!)
//         .maybeSingle();
//
//     String? encKey = conv?['aes_key'] as String?;
//     if (encKey == null) {
//       throw Exception(
//         'AES key not found for this conversation. Please contact support.',
//       );
//     }
//
//     final privKey = EncryptionService.parsePrivateKeyFromPem(
//       _currentUserPrivateKeyPem!,
//     );
//     String aesB64;
//     try {
//       aesB64 = EncryptionService.decryptWithRSA(encKey, privKey);
//       if (!_isValidBase64(aesB64)) throw Exception('Invalid AES key format');
//     } catch (e) {
//       // Decryption failed – do NOT delete or regenerate keys.
//       throw Exception(
//         'Unable to decrypt conversation. Your chat history is preserved, but you cannot send messages. Please start a new conversation.',
//       );
//     }
//     _aesKey = encrypt.Key.fromBase64(aesB64);
//   }


  bool _isValidBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }


  //  Messages with pagination 
Future<void> _loadMessages({required bool initial}) async {
    if (!initial && (_isLoadingMore || !_hasMore)) return;
    if (!initial && mounted) setState(() => _isLoadingMore = true);

    try {
      var query = _supabase
          .from('messages')
          .select()
          .eq('conversation_id', _conversationId!);

      if (!initial && _oldestTimestamp != null) {
        query = query.lt(
          'created_at',
          _oldestTimestamp!.toUtc().toIso8601String(),
        );
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(_pageSize);

      if (data.length < _pageSize) _hasMore = false;
      if (data.isNotEmpty) {
        _oldestTimestamp = DateTime.parse(data.last['created_at'] as String);
      }

      final decoded = data.map(_decodeMessage).toList().reversed.toList();

      if (mounted) {
        setState(() {
          if (initial) {
            _messages = decoded;
            _scrollToBottom();
          } else {
            _messages.insertAll(0, decoded);
          }
          _isLoadingMore = false;
        });
      }

      _loadReactions();
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
      rethrow;
    }
  }

Future<void> _loadReactions() async {
    if (!mounted) return;
    final ids = _messages
        .map((m) => m['id'] as String)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;
    final data = await _supabase
        .from('message_reactions')
        .select()
        .inFilter('message_id', ids);
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in data) {
      final mid = r['message_id'] as String;
      map.putIfAbsent(mid, () => []).add(r);
    }
    if (mounted) {
      setState(() => _reactions.addAll(map));
    }
  }

  Map<String, dynamic> _decodeMessage(Map<String, dynamic> msg) {
    if (msg['is_key_exchange'] == true) {
      return {...msg, 'decrypted_content': 'Secure session established'};
    }
    if (msg['media_url'] != null) {
      return {...msg, 'decrypted_content': null};
    }
    try {
      final text = EncryptionService.decryptWithAES(
        msg['encrypted_content'] as String,
        _aesKey!,
        msg['iv'] as String,
      );
      return {...msg, 'decrypted_content': text};
    } catch (_) {
      return {...msg, 'decrypted_content': '[Unable to decrypt]'};
    }
  }

  //  Realtime 
  void _setupRealtime() {
    _channel = _supabase
        .channel('msgs:${_conversationId!}:$_currentUserId')
    // Listen for INSERT (new messages)
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: _conversationId!,
      ),
  callback: (payload) {
            final newRec = payload.newRecord;
            if (_messages.any(
              (m) => m['id'] != null && m['id'] == newRec['id'],
            ))
              return;
            final decoded = _decodeMessage(newRec);
            if (mounted) {
              setState(() => _messages.add(decoded));
              _scrollToBottom();
              _markMessagesDelivered();
            }
          }
    )
    // Listen for UPDATE (status changes: delivered, seen)
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: _conversationId!,
      ),
      callback: (payload) {
        final updated = payload.newRecord;
        final msgId = updated['id'] as String;
        final index = _messages.indexWhere((m) => m['id'] == msgId);
        if (index != -1) {
          setState(() {
            _messages[index]['status'] = updated['status'];
          });
        }
      },
    )
        .subscribe();
  }

  void _setupTypingIndicator() {
    if (_conversationId == null) return;
    _typingChannel = _supabase.channel('typing:${_conversationId!}');

_typingChannel!.onPresenceSync((_) {
      if (!mounted) return;
      final state = _typingChannel!.presenceState();
      bool typing = false;
      for (final client in state) {
        for (final presence in client.presences) {
          if (presence.payload['user_id'] != _currentUserId &&
              presence.payload['typing'] == true) {
            typing = true;
            break;
          }
        }
      }
      if (mounted) setState(() => _partnerTyping = typing);
    }).subscribe();
  }

  void _updateTyping(bool typing) {
    _typingChannel?.track({'typing': typing, 'user_id': _currentUserId});
  }

  //  Read receipts 
  Future<void> _markMessagesRead() async {
    try {
      await _supabase
          .from('messages')
          .update({'status': 'seen'})
          .eq('conversation_id', _conversationId!)
          .neq('sender_id', _currentUserId)
          .inFilter('status', ['sent', 'delivered']); // only update if not already read
    } catch (_) {}
  }

  Future<void> _markMessagesDelivered() async {
    try {
      await _supabase.from('messages').update({'status': 'delivered'})
          .eq('conversation_id', _conversationId!)
          .neq('sender_id', _currentUserId)
          .eq('status', 'sent');
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  //  Sending 
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _aesKey == null) return;
    _messageController.clear();
    _updateTyping(false);

    final enc = EncryptionService.encryptWithAES(text, _aesKey!);
    final tempId = _uuid.v4();
    final temp = {
      'localId': tempId,
      'id': null,
      'conversation_id': _conversationId,
      'sender_id': _currentUserId,
      'encrypted_content': enc.content,
      'iv': enc.iv,
      'media_url': null,
      'media_type': null,
      'is_key_exchange': false,
      'status': 'sending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'decrypted_content': text,
    };
    setState(() => _messages.add(temp));
    _scrollToBottom();
    try {
      final inserted = await _supabase.from('messages').insert({
        'conversation_id': _conversationId,
        'sender_id': _currentUserId,
        'encrypted_content': enc.content,
        'iv': enc.iv,
        'created_at': DateTime.now().toUtc().toIso8601String(), 

      }).select().single();
      setState(() {
        final idx = _messages.indexWhere((m) => m['localId'] == tempId);
        if (idx != -1) {
          _messages[idx] = {...inserted, 'decrypted_content': text, 'status': 'sent'};
        }
      });
    } catch (e) {
      setState(() {
        final idx = _messages.indexWhere((m) => m['localId'] == tempId);
        if (idx != -1) _messages[idx]['status'] = 'error';
      });
      Get.snackbar('Error', 'Message failed to send');
    }
  }

// Future<void> _ensureConversationExists() async {
//     if (_conversationId != null && _conversationId!.isNotEmpty) return;
//
//     final existing = await _supabase
//         .from('conversations')
//         .select('id')
//         .eq('doctor_id', _currentUserId)
//         .eq('patient_id', widget.partnerId)
//         .maybeSingle();
//
//     if (existing != null) {
//       _conversationId = existing['id'] as String;
//       return;
//     }
//
//     // Fetch public keys
//     final rows = await _supabase
//         .from('user_profiles')
//         .select('id, public_key')
//         .inFilter('id', [_currentUserId, widget.partnerId]);
//
//     final Map<String, String> pubKeys = {};
//     for (final r in rows) {
//       pubKeys[r['id'] as String] = r['public_key'] as String;
//     }
//
//     if (!pubKeys.containsKey(_currentUserId) ||
//         !pubKeys.containsKey(widget.partnerId)) {
//       throw Exception('Encryption keys missing. Please restart the app.');
//     }
//
//     final aesKey = EncryptionService.generateAESKey();
//     final aesB64 = aesKey.base64;
//
//     final encForPatient = EncryptionService.encryptWithRSA(
//       aesB64,
//       EncryptionService.parsePublicKeyFromPem(pubKeys[widget.partnerId]!),
//     );
//     final encForDoctor = EncryptionService.encryptWithRSA(
//       aesB64,
//       EncryptionService.parsePublicKeyFromPem(pubKeys[_currentUserId]!),
//     );
//
//     try {
//       final newConv = await _supabase
//           .from('conversations')
//           .insert({
//             'patient_id': widget.partnerId,
//             'doctor_id': _currentUserId,
//             'aes_key_encrypted_for_patient': encForPatient,
//             'aes_key_encrypted_for_doctor': encForDoctor,
//           })
//           .select('id')
//           .single();
//       _conversationId = newConv['id'] as String;
//     } catch (e) {
//       // Duplicate key error (code 23505) – conversation created by other party
//       if (e.toString().contains('23505')) {
//         final retry = await _supabase
//             .from('conversations')
//             .select('id')
//             .eq('doctor_id', _currentUserId)
//             .eq('patient_id', widget.partnerId)
//             .maybeSingle();
//         if (retry != null) {
//           _conversationId = retry['id'] as String;
//           return;
//         }
//       }
//       rethrow;
//     }
//   }

  Future<void> _uploadAndSendMedia(File file, String type) async {
    if (_sending) return;
    setState(() => _sending = true);

    final localId = _uuid.v4();
    final temp = {
      'localId': localId,
      'id': null,
      'conversation_id': _conversationId,
      'sender_id': _currentUserId,
      'media_url': null,
      'media_type': type,
      'uploading': true,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'decrypted_content': null,
      'status': 'uploading',
    };
    setState(() => _messages.add(temp));
    _scrollToBottom();

    try {
      // 1. Read raw bytes
      final rawBytes = await file.readAsBytes();

      // 2. Encrypt bytes with the conversation AES key
      final encryptedBytes = await EncryptionService.encryptBytes(rawBytes, _aesKey!);

      // 3. Upload encrypted blob — note the .enc extension
      final ext = file.path.split('.').last;
      final path =
          'chat/$_conversationId/${DateTime.now().millisecondsSinceEpoch}.$ext.enc';
      await _supabase.storage
          .from('chat-media')
          .uploadBinary(path, encryptedBytes,
          fileOptions: const FileOptions(contentType: 'application/octet-stream'));

      final url = _supabase.storage.from('chat-media').getPublicUrl(path);

      // 4. Insert message row — media_type carries the original type (image/video)
      final inserted = await _supabase.from('messages').insert({
        'conversation_id': _conversationId,
        'sender_id': _currentUserId,
        'media_url': url,
        'media_type': type,          
        'is_encrypted_media': true,  
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      setState(() {
        final idx = _messages.indexWhere((m) => m['localId'] == localId);
        if (idx != -1) {
          _messages[idx] = {...inserted, 'decrypted_content': null, 'status': 'sent'};
        }
      });
    } catch (e) {
      setState(() {
        final idx = _messages.indexWhere((m) => m['localId'] == localId);
        if (idx != -1) _messages[idx]['status'] = 'error';
      });
      Get.snackbar('Error', 'Media upload failed: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  //  Reactions 
  void _showReactionPicker(String msgId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
            return GestureDetector(
              onTap: () => _toggleReaction(msgId, emoji),
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _toggleReaction(String msgId, String emoji) async {
    final existing = _reactions[msgId]?.firstWhereOrNull(
          (r) => r['user_id'] == _currentUserId && r['emoji'] == emoji,
    );
    if (existing != null) {
      await _supabase.from('message_reactions').delete().eq('id', existing['id']);
      setState(() {
        _reactions[msgId]!.removeWhere((r) => r['id'] == existing['id']);
        if (_reactions[msgId]!.isEmpty) _reactions.remove(msgId);
      });
    } else {
      final inserted = await _supabase.from('message_reactions').insert({
        'message_id': msgId,
        'user_id': _currentUserId,
        'emoji': emoji,
      }).select().single();
      setState(() {
        _reactions.putIfAbsent(msgId, () => []).add(inserted);
      });
    }
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      if (_iAmTyping) {
        _iAmTyping = false;
        _updateTyping(false);
        _typingTimer?.cancel();
      }
      return;
    }
    if (!_iAmTyping) {
      _iAmTyping = true;
      _updateTyping(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _iAmTyping = false;
      _updateTyping(false);
    });
  }

  //  Build 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.partnerName),
            if (_partnerTyping)
              const Text('typing...',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    _scrollController.position.pixels <= 100 &&
                    !_isLoadingMore &&
                    _hasMore) {
                  _loadMessages(initial: false);
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == 0 && _isLoadingMore) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final msg = _messages[i - (_isLoadingMore ? 1 : 0)];
                  return MessageBubble(
                    msg: msg,
                    isMe: msg['sender_id'] == _currentUserId,
                    reactions: _reactions[msg['id']] ?? [],
                    aesKey: _aesKey,                      
                    onLongPress: () => _showReactionPicker(msg['id'] ?? ''),
                    onMediaLongPress: msg['media_url'] != null
                        ? () => _showMediaOptions(msg['media_url'], msg['media_type'])
                        : null,
                  );
                },
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
  void _showMediaOptions(String url, String type) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                MediaDownloadService.downloadAndSave(
                  url,
                  '${DateTime.now().millisecondsSinceEpoch}.${type == 'image' ? 'jpg' : 'mp4'}',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () async {
                Navigator.pop(context);
                // Share directly from URL
                await Share.share(url);
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInputArea() {
    if (!widget.canSendMessages) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade100,
        child: Center(
          child: Text(
            'Messaging is only allowed on the day of the appointment.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: _pickAndSendImages,
              color: AppConstants.primaryColor,
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              onPressed: _pickAndSendVideo,
              color: AppConstants.primaryColor,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.typeAMessage ?? 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            if (_sending)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              CircleAvatar(
                backgroundColor: AppConstants.primaryColor,
                child: IconButton(
                  icon:
                  const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: (){
                    _sendMessage;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}