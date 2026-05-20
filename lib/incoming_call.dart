

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/api_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final bool isVideo;
  /// Called when the user accepts or declines so CallManager can stop the ringtone.
  final VoidCallback? onCallHandled;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.isVideo,
    this.onCallHandled,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {

  // Pulsing avatar rings (3 rings like Messenger)
  late final List<AnimationController> _ringControllers;
  late final List<Animation<double>> _ringAnims;

  // Auto-dismiss
  Timer? _missTimer;
  RealtimeChannel? _callWatcher;

  bool _handled = false;

  @override
  void initState() {
    super.initState();

    // Lock portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Create 3 staggered ring animations
    _ringControllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      );
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) ctrl.repeat();
      });
      return ctrl;
    });

    _ringAnims = _ringControllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOut),
    ))
        .toList();

    // Auto-miss after 60 s
    _missTimer = Timer(const Duration(seconds: 60), _markMissed);

    _watchCallStatus();
  }

  @override
  void dispose() {
    for (final c in _ringControllers) { c.dispose(); }
    _missTimer?.cancel();
    _callWatcher?.unsubscribe();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  //  SUPABASE WATCHER 

  void _watchCallStatus() {
    _callWatcher = Supabase.instance.client
        .channel('incoming_status_${widget.callId}')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'calls',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: widget.callId,
      ),
      callback: (payload) {
        final status = payload.newRecord['status'] as String?;
        if ((status == 'ended' || status == 'missed') && mounted) {
          _dismiss();
        }
      },
    )
        .subscribe();
  }

  //  ACTIONS 

  void _dismiss() {
    if (_handled) return;
    _handled = true;
    widget.onCallHandled?.call();
    if (mounted) Get.back();
  }

  Future<void> _accept() async {
    if (_handled) return;
    _handled = true;
    _missTimer?.cancel();
    widget.onCallHandled?.call();

    Get.off(
          () => CallScreen(
        callId: widget.callId,
        remoteUserId: widget.callerId,
        remoteUserName: widget.callerName,
        isVideo: widget.isVideo,
        isCaller: false,
      ),
      transition: Transition.fadeIn,
    );
  }

  Future<void> _decline() async {
    if (_handled) return;
    _handled = true;
    _missTimer?.cancel();
    widget.onCallHandled?.call();
    try {
      await ApiService.updateCallStatus(
        callId: widget.callId,
        status: 'declined',
      );
    } catch (_) {}
    if (mounted) Get.back();
  }

  Future<void> _markMissed() async {
    if (_handled) return;
    _handled = true;
    widget.onCallHandled?.call();
    try {
      await ApiService.updateCallStatus(
        callId: widget.callId,
        status: 'missed',
      );
    } catch (_) {}
    if (mounted) Get.back();
  }

  //  BUILD 

  @override
  Widget build(BuildContext context) {
    final initials = widget.callerName.isNotEmpty
        ? widget.callerName.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            //  BLURRED GRADIENT BACKGROUND 
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A1A),
                    Color(0xFF0D2137),
                    Color(0xFF0A1628),
                  ],
                ),
              ),
            ),

            // Decorative circle blobs
            Positioned(
              top: -80, left: -80,
              child: _GlowBlob(color: const Color(0xFF1565C0), size: 300),
            ),
            Positioned(
              bottom: -60, right: -60,
              child: _GlowBlob(color: const Color(0xFF0D47A1), size: 250),
            ),

            //  CONTENT 
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Call type label
                  Text(
                    widget.isVideo
                        ? AppLocalizations.of(context)!.incomingVideoCall
                        : AppLocalizations.of(context)!.incomingVoiceCall,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Pulsing rings + avatar
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 3 expanding rings
                        for (int i = 0; i < 3; i++)
                          AnimatedBuilder(
                            animation: _ringAnims[i],
                            builder: (_, __) {
                              final v = _ringAnims[i].value;
                              return Container(
                                width: 130 + v * 60,
                                height: 130 + v * 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(
                                      (1 - v) * 0.35,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),

                        // Avatar circle
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.6),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Caller name
                  Text(
                    widget.callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Call type chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isVideo ? Icons.videocam : Icons.call,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isVideo
                              ? AppLocalizations.of(context)!.videoCall
                              : AppLocalizations.of(context)!.voiceCall,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  //  DECLINE / ACCEPT BUTTONS 
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 48, right: 48, bottom: 56,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ActionButton(
                          icon: Icons.call_end,
                          label: AppLocalizations.of(context)!.decline,
                          color: const Color(0xFFE53935),
                          onTap: _decline,
                        ),
                        _ActionButton(
                          icon: widget.isVideo ? Icons.videocam : Icons.call,
                          label: AppLocalizations.of(context)!.accept,
                          color: const Color(0xFF43A047),
                          onTap: _accept,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  SUB-WIDGETS 

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(0.18),
    ),
  );
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sc;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _sc = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1, end: 0.9).animate(_sc);
  }

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _sc.forward(),
      onTapUp: (_) { _sc.reverse(); widget.onTap(); },
      onTapCancel: () => _sc.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}