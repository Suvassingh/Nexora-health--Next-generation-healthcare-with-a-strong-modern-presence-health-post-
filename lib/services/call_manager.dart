

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../incoming_call.dart';

class CallManager {
  CallManager._();
  static final instance = CallManager._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  bool _initialized = false;

  // Ringtone player
  AudioPlayer? _ringtonePlayer;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  //  INIT 

  void init() {
    if (_initialized || _currentUserId == null) return;
    _initialized = true;
    debugPrint('🔔 CallManager init for $_currentUserId');

    _channel = _supabase
        .channel('incoming_calls_$_currentUserId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'calls',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'callee_id',
        value: _currentUserId!,
      ),
      callback: (payload) {
        debugPrint('📞 CallManager: ${payload.newRecord}');
        _handleIncomingCall(payload.newRecord);
      },
    )
        .subscribe((status, [err]) {
      debugPrint('[CallManager] $status err=$err');
    });
  }

  //  RINGTONE 

  Future<void> _startRingtone() async {
    try {
      _ringtonePlayer = AudioPlayer();
    
      await _ringtonePlayer!.setAsset('assets/sounds/ringtone.mp3');
      await _ringtonePlayer!.setLoopMode(LoopMode.one);
      await _ringtonePlayer!.play();
    } catch (e) {
      debugPrint('[CallManager] ringtone error: $e');
    }
  }

  Future<void> stopRingtone() async {
    await _ringtonePlayer?.stop();
    await _ringtonePlayer?.dispose();
    _ringtonePlayer = null;
  }

  //  HANDLE INCOMING CALL 

  Future<void> _handleIncomingCall(Map<String, dynamic> record) async {
    final callId   = record['id']        as String;
    final callerId = record['caller_id'] as String;
    final callType = record['call_type'] as String;

    // Fetch caller's display name
    String callerName = 'Unknown';
    try {
      final profile = await _supabase
          .from('user_profiles')
          .select('full_name')
          .eq('id', callerId)
          .single();
      callerName = profile['full_name']?.toString() ?? 'Unknown';
    } catch (_) {}

    // Start ringing
    await _startRingtone();

    // Show full-screen incoming call UI
    Get.to(
          () => IncomingCallScreen(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        isVideo: callType == 'video',
        onCallHandled: stopRingtone, // stop ring on accept / decline
      ),
      fullscreenDialog: true,
    );
  }

  //  DISPOSE 

  void dispose() {
    _channel?.unsubscribe();
    stopRingtone();
    _initialized = false;
  }

  void reset() {
    _channel?.unsubscribe();
    _initialized = false;
    init();
  }
}