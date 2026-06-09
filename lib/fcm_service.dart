import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:healthpost_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    // 1. Send current token if user already logged in
    await _sendCurrentToken();

    // 2. Listen for token refreshes (background rotation)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _sendCurrentToken(token: newToken);
    });
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  }
@pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    final data = message.data;
    if (data['type'] == 'missed_call') {
      // Show local notification even when app is terminated
      await _showMissedCallNotification(data);
    }
  }
static Future<void> _showMissedCallNotification(
    Map<String, dynamic> data,
  ) async {
    final callerName = data['callerName'] ?? 'Unknown';
    final callId =
        data['callId'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    await NotificationService.instance.showLocalNotification(
      id: callId.hashCode,
      title: 'Missed Call',
      body: 'Missed call from $callerName',
      payload: {'type': 'missed_call', 'callId': callId},
    );
  }
  /// Call after EVERY successful login (email/password, Google, etc.)
  static Future<void> onUserLogin() async {
    await _sendCurrentToken();
  }

  /// Call on explicit logout – removes all tokens for the current user
  static Future<void> onUserLogout() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('fcm_tokens').delete().eq('user_id', userId);
      debugPrint('🧹 Cleared FCM tokens for user $userId');
    } catch (e) {
      debugPrint('⚠️ Failed to clear tokens: $e');
    }
  }

  //  internal 
  static Future<void> _sendCurrentToken({String? token}) async {
    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final user = _supabase.auth.currentUser;
      if (user == null) return; 
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      await _supabase.functions.invoke('update-fcm-token', body: {
        'token': fcmToken,
        'platform': platform,
      });
      debugPrint('FCM token synced for user ${user.id}');
    } catch (e) {
      debugPrint(' FCM token sync failed: $e');
    }
  }
}