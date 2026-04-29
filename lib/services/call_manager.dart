// lib/services/call_manager.dart
// Initialize once after login. Listens for incoming calls via Supabase Realtime
// and navigates to IncomingCallScreen automatically — no FCM needed.
//
// Usage in your auth controller / home screen initState:
//   CallManager.instance.init();
//
// Dispose in logout:
//   CallManager.instance.dispose();

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/incoming_call.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// !! Change this import to match your app's package name !!
// Patient app  : import 'package:patient_app/screens/incoming_call_screen.dart';
// Doctor app   : import 'package:healthpost_app/screens/incoming_call_screen.dart';

class CallManager {
  CallManager._();
  static final instance = CallManager._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  bool _initialized = false;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ── INIT ──────────────────────────────────────────────────────────────────

  void init() {
    if (_initialized || _currentUserId == null) return;
    _initialized = true;

    debugPrint('🔔 CallManager init for user: $_currentUserId');

    _channel = _supabase
        .channel('incoming_calls_$_currentUserId')
        .onPostgresChanges(
      event:  PostgresChangeEvent.insert,
      schema: 'public',
      table:  'calls',
      // ── REMOVE the filter entirely for now to test ──
      // filter: PostgresChangeFilter(...),
      callback: (payload) {
        debugPrint('📞 CallManager received: ${payload.newRecord}');
        final record = payload.newRecord;
        // Only handle if we are the callee
        if (record['callee_id'] == _currentUserId) {
          _handleIncomingCall(record);
        }
      },
    )
        .subscribe((status, [err]) {
      debugPrint('[CallManager] status=$status err=$err');
    });
  }

  // ── HANDLE NEW INCOMING CALL ───────────────────────────────────────────────

  Future<void> _handleIncomingCall(Map<String, dynamic> record) async {
    final callId = record['id'] as String;
    final callerId = record['caller_id'] as String;
    final callType = record['call_type'] as String;

    // Fetch caller name
    String callerName = 'Unknown';
    try {
      final profile = await _supabase
          .from('user_profiles')
          .select('full_name')
          .eq('id', callerId)
          .single();
      callerName = profile['full_name']?.toString() ?? 'Unknown';
    } catch (_) {}

    // Navigate to ringing screen
    Get.to(
      () => IncomingCallScreen(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        isVideo: callType == 'video',
      ),
      fullscreenDialog: true,
    );
  }

  // ── DISPOSE ───────────────────────────────────────────────────────────────

  void dispose() {
    _channel?.unsubscribe();
    _initialized = false;
  }
}
