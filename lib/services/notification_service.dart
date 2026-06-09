
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

  //  INIT 
  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);

    //  DO NOT BLOCK APP STARTUP
    Future.microtask(() => _saveToken());

    _messaging.onTokenRefresh.listen(_uploadToken);
  }

  //  LOGIN 
  Future<void> onUserLoggedIn() async {
    Future.microtask(() => _saveToken());
    _subscribeRealtime();
  }

  Future<void> onUserLoggedOut() async {
    await _unsubscribeRealtime();
    await _deleteToken();
  }

  //  LOCAL NOTIFICATIONS 
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
          AndroidFlutterLocalNotificationsPlugin>()
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

  //  TOKEN HANDLING (FIXED) 
  Future<void> _saveToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _uploadToken(token);
    } catch (e) {
      print("FCM getToken failed (ignored): $e");
    }
  }

  Future<void> _uploadToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      print("Token upload failed: $e");
    }
  }

  Future<void> _deleteToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = await _messaging.getToken();

      if (token != null) {
        await _supabase
            .from('fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
      }

      await _messaging.deleteToken();
    } catch (e) {
      print("FCM deleteToken failed (ignored): $e");
    }
  }

  //  REALTIME 
  void _subscribeRealtime() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
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
          _inAppController.add(
            AppNotification.fromJson(payload.newRecord),
          );
        },
      )
          .subscribe();
    } catch (e) {
      print("Realtime subscribe failed: $e");
    }
  }

  Future<void> _unsubscribeRealtime() async {
    if (_realtimeChannel != null) {
      await _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }
// Inside NotificationService class
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
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
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }
  //  MESSAGE HANDLING 
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
      // Get.to(() => const ChatScreen());
        break;

      default:
        break;
    }
  }

  //  DISPOSE 
  void dispose() {
    _inAppController.close();
  }
}