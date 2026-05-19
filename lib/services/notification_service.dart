

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';
import '../appointment_screen.dart'; 
import '../chat_screen.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _supabase = Supabase.instance.client;

  final _inAppController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get inAppStream => _inAppController.stream;

  RealtimeChannel? _realtimeChannel;

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _initLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
    await _saveToken();
    _messaging.onTokenRefresh.listen(_uploadToken);
  }

  Future<void> onUserLoggedIn() async {
    await _saveToken();
    _subscribeRealtime();
  }

  Future<void> onUserLoggedOut() async {
    await _unsubscribeRealtime();
    await _deleteToken();
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _routeFromPayload(
            jsonDecode(details.payload!) as Map<String, dynamic>,
          );
        }
      },
    );
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'healthpost_channel',
              'HealthPost Notifications',
              description: 'Appointment and consultation alerts',
              importance: Importance.high,
              playSound: true,
            ),
          );
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'healthpost_channel',
          'HealthPost Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _saveToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _uploadToken(token);
  }

  Future<void> _uploadToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('fcm_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }

  Future<void> _deleteToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _supabase
        .from('fcm_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('token', token);
    await _messaging.deleteToken();
  }

  void _subscribeRealtime() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _realtimeChannel = _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _inAppController.add(AppNotification.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  Future<void> _unsubscribeRealtime() async {
    if (_realtimeChannel != null) {
      await _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    _routeFromPayload(message.data);
  }

  void _routeFromPayload(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_appointment':
      case 'appointment_cancelled':
        Get.to(() => const DoctorAppointmentsScreen());
        break;
      case 'chat_message':
       
        break;
      default:
        break;
    }
  }

  void dispose() => _inAppController.close();
}
