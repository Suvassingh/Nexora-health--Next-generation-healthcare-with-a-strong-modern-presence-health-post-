
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  static final _supabase = Supabase.instance.client;
  static Timer? _heartbeat;

  static void startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 50), (_) async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('user_profiles').update({
        'is_online': true,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    });
  }

  static void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  static Future<void> setOffline() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('user_profiles').update({
      'is_online': false,
      'last_seen': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }
}