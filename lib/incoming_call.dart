// lib/screens/incoming_call_screen.dart
// Works in BOTH apps — just adjust the ApiService import path.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// !! Adjust import to your app's package !!
// import 'package:patient_app/services/api_service.dart';
// import 'package:patient_app/screens/call_screen.dart';
import '../services/api_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final bool isVideo;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.isVideo,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  // Auto-miss after 60 s if no answer
  Timer? _missTimer;

  RealtimeChannel? _callWatcher;

  @override
  void initState() {
    super.initState();

    // Pulsing avatar animation
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    // Auto-miss timer
    _missTimer = Timer(const Duration(seconds: 60), _markMissed);

    // Watch for caller hanging up before we answer
    _watchCallStatus();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _missTimer?.cancel();
    _callWatcher?.unsubscribe();
    super.dispose();
  }

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
            if (status == 'ended' || status == 'missed') {
              if (mounted) Get.back();
            }
          },
        )
        .subscribe();
  }

  Future<void> _accept() async {
    _missTimer?.cancel();
    // Navigate to call screen as callee
    Get.off(
      () => CallScreen(
        callId: widget.callId,
        remoteUserId: widget.callerId,
        remoteUserName: widget.callerName,
        isVideo: widget.isVideo,
        isCaller: false,
      ),
    );
  }

  Future<void> _decline() async {
    _missTimer?.cancel();
    try {
      await ApiService.dio.patch(
        '/calls/${widget.callId}/status',
        data: {'status': 'declined'},
      );
    } catch (_) {}
    if (mounted) Get.back();
  }

  Future<void> _markMissed() async {
    try {
      await ApiService.dio.patch(
        '/calls/${widget.callId}/status',
        data: {'status': 'missed'},
      );
    } catch (_) {}
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent back-button dismissal
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1A237E)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── TOP SPACER ──────────────────────────────────────────────
                const Spacer(),

                // ── CALLER INFO ─────────────────────────────────────────────
                Text(
                  widget.isVideo
                      ? 'Incoming Video Call'
                      : 'Incoming Audio Call',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Pulsing avatar
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.callerName.isNotEmpty
                            ? widget.callerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isVideo ? Icons.videocam : Icons.call,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isVideo ? 'Video Call' : 'Audio Call',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),

                // ── BOTTOM SPACER ───────────────────────────────────────────
                const Spacer(),

                // ── ACCEPT / DECLINE ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 56,
                    left: 48,
                    right: 48,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline
                      _RingButton(
                        color: Colors.red,
                        icon: Icons.call_end,
                        label: 'Decline',
                        onTap: _decline,
                      ),
                      // Accept
                      _RingButton(
                        color: Colors.green,
                        icon: widget.isVideo ? Icons.videocam : Icons.call,
                        label: 'Accept',
                        onTap: _accept,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RingButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
