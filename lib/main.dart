
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';

import 'fcm_service.dart';
import 'l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'services/presence_service.dart';
import 'controller/internet_status_controller.dart';
import 'livekit_screen.dart';
import 'splash_screen.dart';

//  GLOBAL NAV KEY 
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//  BACKGROUND HANDLER 
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;

  if (data['type'] == 'incoming_call') {
    final params = CallKitParams(
      id: data['appointmentId'] ?? '',
      nameCaller: data['callerName'] ?? 'Unknown',
      handle: data['callerName'] ?? 'Call',
      type: data['callType'] == 'video' ? 1 : 0,
      duration: 30000,
      extra: {
        'roomName': data['roomName'],
        'token': data['token'],
        'callType': data['callType'],
        'callerId': data['callerId'],
        'appointmentId': data['appointmentId'],
      },
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}

//  MAIN 
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['supabase_url']!,
    anonKey: dotenv.env['supabase_anonKey']!,
  );

  final supabase = Supabase.instance.client;
  supabase.auth.onAuthStateChange.listen((event) {
    if (event.event == AuthChangeEvent.signedIn) {
      final user = event.session?.user;

      if (user != null && user.emailConfirmedAt == null) {
        debugPrint('Unverified user blocked: ${user.email}');
        Supabase.instance.client.auth.signOut();
        return;
      }
      debugPrint('Doctor signed in: ${user?.id}');
    }
    switch (event.event) {
      case AuthChangeEvent.tokenRefreshed:
        debugPrint(' Token refreshed');
        break;
      case AuthChangeEvent.signedOut:
        debugPrint(' Doctor signed out');
        PresenceService.stopHeartbeat();
        PresenceService.setOffline();
        break;
      case AuthChangeEvent.signedIn:
        debugPrint(' Doctor signed in: ${event.session?.user.id}');
        PresenceService.startHeartbeat();
        break;
      default:
        break;
    }
  }, onError: (error) {
    debugPrint('Auth stream error: $error');
  });

  if (supabase.auth.currentSession == null) {
    debugPrint(' No active session on startup');
  } else {
    debugPrint('User already signed in: ${supabase.auth.currentUser?.id}');
    PresenceService.startHeartbeat();
  }

  //  Notification permission
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    // Permission request already in progress (hot restart). Ignore.
    debugPrint('Permission request skipped: $e');
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize();
  await FcmService.initialize();

  Get.put(ConnectivityController(), permanent: true);
  await TtsService().init();

  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString("language") ?? "en";

  runApp(ProviderScope(child: HealthpostApp(languageCode: languageCode)));

  //  SAFE LISTENERS (AFTER APP START) 
  _initMessagingListeners();
  _initCallKitListener();
}

//  SAFE FCM LISTENER 
void _initMessagingListeners() {
  FirebaseMessaging.onMessage.listen((message) async {
    final data = message.data;
    if (data['type'] == 'incoming_call') {
      final params = CallKitParams(
        id: data['appointmentId'] ?? '',
        nameCaller: data['callerName'] ?? 'Unknown',
        handle: data['callerName'] ?? 'Call',
        type: data['callType'] == 'video' ? 1 : 0,
        duration: 30000,
        extra: {
          'roomName': data['roomName'],
          'token': data['token'],
          'callType': data['callType'],
          'callerId': data['callerId'],
          'appointmentId': data['appointmentId'],
        },
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    }
  });
}

//  SAFE CALLKIT LISTENER 
void _initCallKitListener() {
  FlutterCallkitIncoming.onEvent.listen((event) async {
    if (event is! CallEvent) return;

    final body = event.body;

    switch (event.event) {
      case Event.actionCallAccept:
        final extra = Map<String, dynamic>.from(body['extra'] ?? {});
        final roomName = extra['roomName'] as String?;
        final token = extra['token'] as String?;
        final callType = extra['callType'] as String?;
        final callerName = body['nameCaller'] ?? 'Unknown';

        if (roomName != null && token != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => LiveKitCallScreen(
                livekitUrl: 'ws://45.115.217.244:7880',
                token: token,
                roomName: roomName,
                remoteUserName: callerName,
                isVideo: callType == 'video',
                isCaller: false,
              ),
            ),
          );
        }
        break;

      case Event.actionCallDecline:
      case Event.actionCallTimeout:
        final callId = body['id'] as String?;
        if (callId != null) {
          await FlutterCallkitIncoming.endCall(callId);
        }
        break;

      default:
        break;
    }
  });
}

//  APP 
class HealthpostApp extends StatefulWidget {
  final String languageCode;
  const HealthpostApp({super.key, required this.languageCode});

  static HealthpostAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<HealthpostAppState>();

  @override
  State<HealthpostApp> createState() => HealthpostAppState();
}

class HealthpostAppState extends State<HealthpostApp>
    with WidgetsBindingObserver {
  String get currentLanguageCode => _locale.languageCode;

  late Locale _locale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locale = Locale(widget.languageCode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void changeLanguage(String code) async {
    setState(() => _locale = Locale(code));
    Get.updateLocale(Locale(code));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", code);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      PresenceService.stopHeartbeat();
      PresenceService.setOffline();
    } else if (state == AppLifecycleState.resumed) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && !session.isExpired) {
        PresenceService.startHeartbeat();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('ne')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}