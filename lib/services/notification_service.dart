// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Background handler (runs in a separate isolate)
// // ─────────────────────────────────────────────────────────────────────────────
// @pragma('vm:entry-point')
// Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
//   // Create a fresh plugin instance for this isolate
//   final local = FlutterLocalNotificationsPlugin();
//
//   // Initialize with the same settings as the main isolate
//   const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//   const ios = DarwinInitializationSettings();
//   const settings = InitializationSettings(android: android, iOS: ios);
//
//   //  Version 20.1.0: initialize takes a POSITIONAL argument
//   await local.initialize(settings);
//
//   // Show the notification using this isolate's plugin
//   await NotificationService.showLocalWithInstance(local, message);
// }
//
// class NotificationService {
//   static final _fcm = FirebaseMessaging.instance;
//   static final _local = FlutterLocalNotificationsPlugin();
//   static final _supa = Supabase.instance.client;
//
//   static const _channel = AndroidNotificationChannel(
//     'healthpost_main',
//     'HealthPost Notifications',
//     description: 'Appointment and call notifications',
//     importance: Importance.high,
//   );
//
//   static Future<void> init() async {
//     // 1. Request permissions
//     await _fcm.requestPermission(alert: true, badge: true, sound: true);
//
//     // 2. Create Android notification channel
//     await _local
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(_channel);
//
//     // 3. Initialize local notifications (main isolate)
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const ios = DarwinInitializationSettings();
//     const settings = InitializationSettings(android: android, iOS: ios);
//
//     //  Version 20.1.0: initialize takes a POSITIONAL argument
//     await _local.initialize(
//       settings,
//       onDidReceiveNotificationResponse: _onNotificationTap,
//     );
//
//     // 4. Set background message handler
//     FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
//
//     // 5. Handle foreground messages
//     FirebaseMessaging.onMessage.listen(showLocal);
//
//     // 6. Handle notification tap when app is opened from background
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigate);
//
//     // 7. Save FCM token
//     await _saveToken();
//     _fcm.onTokenRefresh.listen((_) => _saveToken());
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────
//   // Save token to Supabase
//   // ─────────────────────────────────────────────────────────────────────────
//   static Future<void> _saveToken() async {
//     final uid = _supa.auth.currentUser?.id;
//     final token = await _fcm.getToken();
//     if (uid == null || token == null) return;
//
//     await _supa
//         .from('user_profiles')
//         .update({
//       'fcm_token': token,
//       'fcm_updated_at': DateTime.now().toIso8601String(),
//     })
//         .eq('id', uid);
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────
//   // Show notification (foreground) using main plugin instance
//   // ─────────────────────────────────────────────────────────────────────────
//   static Future<void> showLocal(RemoteMessage message) async {
//     await showLocalWithInstance(_local, message);
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────
//   // Show notification using a given plugin instance (used by both isolates)
//   // ─────────────────────────────────────────────────────────────────────────
//   static Future<void> showLocalWithInstance(
//       FlutterLocalNotificationsPlugin local,
//       RemoteMessage message,
//       ) async {
//     final n = message.notification;
//     if (n == null) return;
//
//     final id = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
//
//     //  Version 20.1.0: show uses NAMED parameters
//     await local.show(
//       id: id,
//       title: n.title ?? '',
//       body: n.body ?? '',
//       notificationDetails: NotificationDetails(
//         android: AndroidNotificationDetails(
//           _channel.id,
//           _channel.name,
//           channelDescription: _channel.description,
//           importance: Importance.high,
//           priority: Priority.high,
//           icon: '@mipmap/ic_launcher',
//         ),
//         iOS: const DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: true,
//         ),
//       ),
//       payload: message.data['route']?.toString(),
//     );
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────
//   // Handle tap on local notification (when app is in foreground or background)
//   // ─────────────────────────────────────────────────────────────────────────
//   static void _onNotificationTap(NotificationResponse response) {
//     final route = response.payload;
//     if (route == 'appointments') {
//       print("Navigate to appointments screen");
//       // TODO: Add actual navigation logic
//     } else if (route == 'call') {
//       print("Navigate to call screen");
//       // TODO: Add actual navigation logic
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────────────
//   // Handle app opened from a notification (via Firebase)
//   // ─────────────────────────────────────────────────────────────────────────
//   static void _handleNavigate(RemoteMessage message) {
//     _onNotificationTap(
//       NotificationResponse(
//         notificationResponseType: NotificationResponseType.selectedNotification,
//         payload: message.data['route']?.toString(),
//       ),
//     );
//   }
// }