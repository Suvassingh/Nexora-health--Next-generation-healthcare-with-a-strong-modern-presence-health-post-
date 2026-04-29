// lib/screens/call_screen.dart
// Works in BOTH apps — adjust import paths for your package name.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// !! Adjust imports to your app's package !!
// import 'package:patient_app/services/webrtc_service.dart';
// import 'package:patient_app/services/api_service.dart';
import '../services/webrtc_service.dart';
import '../services/api_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String remoteUserId;
  final String remoteUserName;
  final bool isVideo;
  final bool isCaller; // true = outgoing call, false = incoming

  const CallScreen({
    super.key,
    required this.callId,
    required this.remoteUserId,
    required this.remoteUserName,
    required this.isVideo,
    required this.isCaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _webrtc = WebRTCService();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final _supabase = Supabase.instance.client;

  bool _muted = false;
  bool _cameraOff = false;
  bool _speakerOn = true;
  bool _connected = false;
  bool _loading = true;
  bool _ended = false;

  String _statusText = 'Connecting…';
  Timer? _timer;
  int _seconds = 0;

  RealtimeChannel? _callWatcher;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  // ── INIT ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Lock to portrait so video layout is predictable
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _init();
    _watchCallStatus();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _webrtc.onRemoteStream = (stream) {
      if (!mounted) return;
      setState(() {
        _remoteRenderer.srcObject = stream;
        _connected = true;
        _statusText = 'Connected';
      });
      _startTimer();
      // Turn on speaker automatically for video calls
      if (widget.isVideo) _webrtc.setSpeaker(true);
    };

    _webrtc.onCallEnded = () {
      if (!_ended) _endCall(sendSignal: false);
    };

    try {
      final local = await _webrtc.getLocalStream(isVideo: widget.isVideo);
      if (mounted) setState(() => _localRenderer.srcObject = local);

      if (widget.isCaller) {
        setState(() => _statusText = 'Ringing…');
        await _webrtc.startAsCallerCall(
          callId: widget.callId,
          currentUserId: _currentUserId,
          isVideo: widget.isVideo,
        );
      } else {
        setState(() => _statusText = 'Connecting…');
        await _webrtc.startAsCalleeCall(
          callId: widget.callId,
          currentUserId: _currentUserId,
          isVideo: widget.isVideo,
        );
        // Mark call as accepted
        await ApiService.dio.patch(
          '/calls/${widget.callId}/status',
          data: {'status': 'accepted'},
        );
      }
    } catch (e) {
      if (mounted) Get.snackbar('Call Error', e.toString());
      Get.back();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── CALL STATUS WATCHER ───────────────────────────────────────────────────

  void _watchCallStatus() {
    _callWatcher = _supabase
        .channel('call_watch_${widget.callId}_$_currentUserId')
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
            if ((status == 'ended' || status == 'declined') && !_ended) {
              _endCall(sendSignal: false);
            }
          },
        )
        .subscribe();
  }

  // ── TIMER ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get _timerLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── END CALL ──────────────────────────────────────────────────────────────

  Future<void> _endCall({bool sendSignal = true}) async {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();

    if (sendSignal) {
      await _webrtc.hangup();
      try {
        await ApiService.dio.patch(
          '/calls/${widget.callId}/status',
          data: {'status': 'ended'},
        );
      } catch (_) {}
    } else {
      await _webrtc.dispose();
    }

    if (mounted) Get.back();
  }

  // ── DISPOSE ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    _callWatcher?.unsubscribe();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtc.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _endCall(),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Stack(
          children: [
            // ── BACKGROUND / REMOTE VIDEO ───────────────────────────────────
            if (widget.isVideo && _connected)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              _AudioBackground(name: widget.remoteUserName),

            // ── LOCAL PIP ───────────────────────────────────────────────────
            if (widget.isVideo)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 100,
                    height: 140,
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // ── TOP BAR ─────────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                name: widget.remoteUserName,
                statusText: _connected ? _timerLabel : _statusText,
                hasGradient: widget.isVideo && _connected,
              ),
            ),

            // ── BOTTOM CONTROLS ─────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomControls(
                isVideo: widget.isVideo,
                muted: _muted,
                cameraOff: _cameraOff,
                speakerOn: _speakerOn,
                onMute: () => setState(() {
                  _muted = !_muted;
                  _webrtc.setMuted(_muted);
                }),
                onCamera: () => setState(() {
                  _cameraOff = !_cameraOff;
                  _webrtc.setCameraOff(_cameraOff);
                }),
                onSpeaker: () => setState(() {
                  _speakerOn = !_speakerOn;
                  _webrtc.setSpeaker(_speakerOn);
                }),
                onFlip: () => _webrtc.switchCamera(),
                onEnd: () => _endCall(),
              ),
            ),

            // ── LOADING OVERLAY ─────────────────────────────────────────────
            if (_loading)
              const ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── SUB-WIDGETS ───────────────────────────────────────────────────────────────

class _AudioBackground extends StatelessWidget {
  final String name;
  const _AudioBackground({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1A1A2E)],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  final String name;
  final String statusText;
  final bool hasGradient;
  const _TopBar({
    required this.name,
    required this.statusText,
    required this.hasGradient,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 16,
      bottom: 20,
      left: 24,
      right: 24,
    ),
    decoration: hasGradient
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          )
        : null,
    child: Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          statusText,
          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14),
        ),
      ],
    ),
  );
}

class _BottomControls extends StatelessWidget {
  final bool isVideo;
  final bool muted;
  final bool cameraOff;
  final bool speakerOn;
  final VoidCallback onMute;
  final VoidCallback onCamera;
  final VoidCallback onSpeaker;
  final VoidCallback onFlip;
  final VoidCallback onEnd;

  const _BottomControls({
    required this.isVideo,
    required this.muted,
    required this.cameraOff,
    required this.speakerOn,
    required this.onMute,
    required this.onCamera,
    required this.onSpeaker,
    required this.onFlip,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom + 28,
      top: 24,
      left: 24,
      right: 24,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.black87, Colors.transparent],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Control buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Btn(
              icon: muted ? Icons.mic_off : Icons.mic,
              label: muted ? 'Unmute' : 'Mute',
              active: muted,
              onTap: onMute,
            ),
            if (isVideo)
              _Btn(
                icon: cameraOff ? Icons.videocam_off : Icons.videocam,
                label: cameraOff ? 'Cam On' : 'Cam Off',
                active: cameraOff,
                onTap: onCamera,
              ),
            _Btn(
              icon: speakerOn ? Icons.volume_up : Icons.hearing,
              label: speakerOn ? 'Speaker' : 'Earpiece',
              active: false,
              onTap: onSpeaker,
            ),
            if (isVideo)
              _Btn(
                icon: Icons.flip_camera_ios,
                label: 'Flip',
                active: false,
                onTap: onFlip,
              ),
          ],
        ),
        const SizedBox(height: 32),
        // End call
        GestureDetector(
          onTap: onEnd,
          child: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
          ),
        ),
      ],
    ),
  );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Btn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.white.withOpacity(0.18),
          ),
          child: Icon(
            icon,
            color: active ? Colors.black87 : Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );
}
