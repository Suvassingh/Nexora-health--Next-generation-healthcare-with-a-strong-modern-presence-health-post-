

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:healthpost_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/webrtc_service.dart';
import '../services/api_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String remoteUserId;
  final String remoteUserName;
  final bool isVideo;
  final bool isCaller;

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

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {

  final _webrtc = WebRTCService();
  final _localRenderer  = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final _supabase = Supabase.instance.client;

  bool _muted      = false;
  bool _cameraOff  = false;
  bool _speakerOn  = true;
  bool _connected  = false;
  bool _loading    = true;
  bool _ended      = false;
  bool _controlsVisible = true;

  String _statusText = '';
  Timer? _callTimer;
  Timer? _controlsTimer;
  int _seconds = 0;

  RealtimeChannel? _callWatcher;

  // Controls auto-hide animation
  late final AnimationController _ctrlAnim;
  late final Animation<double> _ctrlFade;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  //  INIT 

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        setState(() => _statusText = AppLocalizations.of(context)!.connecting);
    });
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _ctrlAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250),
      value: 1,
    );
    _ctrlFade = CurvedAnimation(parent: _ctrlAnim, curve: Curves.easeInOut);

    _init();
    _watchCallStatus();
  }

  Future<void> _init() async {
      final l = AppLocalizations.of(context)!;
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _webrtc.onRemoteStream = (stream) {
      if (!mounted) return;
      setState(() {
        _remoteRenderer.srcObject = stream;
        _connected  = true;
         _statusText = l.connected; 
      });
      _startCallTimer();
      if (widget.isVideo) _webrtc.setSpeaker(true);
      _scheduleControlsHide();
    };

    _webrtc.onCallEnded = () {
      if (!_ended) _endCall(sendSignal: false);
    };

    try {
      final local = await _webrtc.getLocalStream(isVideo: widget.isVideo);
      if (mounted) setState(() => _localRenderer.srcObject = local);

      if (widget.isCaller) {
        if (mounted) setState(() => _statusText = l.ringing);
        await _webrtc.startAsCallerCall(
          callId: widget.callId,
          currentUserId: _currentUserId,
          isVideo: widget.isVideo,
        );
      } else {
        if (mounted) setState(() => _statusText = l.connecting);
        await _webrtc.startAsCalleeCall(
          callId: widget.callId,
          currentUserId: _currentUserId,
          isVideo: widget.isVideo,
        );
        await ApiService.updateCallStatus(
          callId: widget.callId,
          status: 'accepted',
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          l.callError,
          e.toString(),
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
        );
        Get.back();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  //  CALL STATUS WATCHER 

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

  //  TIMER 

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get _timerLabel {
    final h = _seconds ~/ 3600;
    final m = (_seconds % 3600) ~/ 60;
    final s = _seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    }
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  //  CONTROLS AUTO-HIDE 

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
      _ctrlAnim.forward();
    }
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.isVideo && _connected) {
        setState(() => _controlsVisible = false);
        _ctrlAnim.reverse();
      }
    });
  }

  void _onTapScreen() => _scheduleControlsHide();

  //  END CALL 

  Future<void> _endCall({bool sendSignal = true}) async {
    if (_ended) return;
    _ended = true;
    _callTimer?.cancel();
    _controlsTimer?.cancel();

    if (sendSignal) {
      await _webrtc.hangup();
      try {
        await ApiService.updateCallStatus(
          callId: widget.callId,
          status: 'ended',
        );
      } catch (_) {}
    } else {
      await _webrtc.dispose();
    }

    if (mounted) Get.back();
  }

  //  DISPOSE 

  @override
  void dispose() {
    _callTimer?.cancel();
    _controlsTimer?.cancel();
    _ctrlAnim.dispose();
    _callWatcher?.unsubscribe();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtc.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  //  BUILD 

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _endCall(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTapScreen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              //  REMOTE VIDEO / AUDIO BG 
              if (widget.isVideo && _connected)
                RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
                _AudioCallBackground(name: widget.remoteUserName),

              //  LOCAL PIP (video only) 
              if (widget.isVideo)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: _LocalPip(renderer: _localRenderer),
                ),

              //  TOP INFO BAR 
              FadeTransition(
                opacity: _ctrlFade,
                child: _TopBar(
                  name: widget.remoteUserName,
                  statusText: _connected ? _timerLabel : _statusText,
                  isVideo: widget.isVideo,
                  isConnected: _connected,
                ),
              ),

              //  BOTTOM CONTROLS 
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: FadeTransition(
                  opacity: _ctrlFade,
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
                    onFlip: _webrtc.switchCamera,
                    onEnd: () => _endCall(),
                  ),
                ),
              ),

              //  LOADING OVERLAY 
              if (_loading)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 20),
                       Text(
                          AppLocalizations.of(context)!.settingUpCall,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

//  AUDIO CALL BACKGROUND 

class _AudioCallBackground extends StatelessWidget {
  final String name;
  const _AudioCallBackground({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D2137), Color(0xFF0A1628), Color(0xFF060E1A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  LOCAL PIP 

class _LocalPip extends StatelessWidget {
  final RTCVideoRenderer renderer;
  const _LocalPip({required this.renderer});

  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.hardEdge,
    child: SizedBox(
      width: 100,
      height: 140,
      child: RTCVideoView(
        renderer,
        mirror: true,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    ),
  );
}

//  TOP BAR 

class _TopBar extends StatelessWidget {
  final String name;
  final String statusText;
  final bool isVideo;
  final bool isConnected;
  const _TopBar({
    required this.name,
    required this.statusText,
    required this.isVideo,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 16,
      bottom: 24, left: 24, right: 24,
    ),
    decoration: isVideo && isConnected
        ? const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black87, Colors.transparent],
      ),
    )
        : null,
    child: Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isConnected)
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF43A047),
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              statusText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

//  BOTTOM CONTROLS 

class _BottomControls extends StatelessWidget {
  final bool isVideo;
  final bool muted;
  final bool cameraOff;
  final bool speakerOn;
  final VoidCallback onMute;
  final VoidCallback onCamera;
  final VoidCallback onSpeaker;
  final AsyncCallback onFlip;
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
      bottom: MediaQuery.of(context).padding.bottom + 32,
      top: 24, left: 20, right: 20,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.black, Colors.transparent],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Secondary controls row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CtrlBtn(
              icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
label: muted
                  ? AppLocalizations.of(context)!.unmute
                  : AppLocalizations.of(context)!.mute,              active: muted,
              onTap: onMute,
            ),
            if (isVideo)
              _CtrlBtn(
                icon: cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                label: cameraOff
                    ? AppLocalizations.of(context)!.camOn
                    : AppLocalizations.of(context)!.camOff,
                active: cameraOff,
                onTap: onCamera,
              ),
            _CtrlBtn(
              icon: speakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
              label: speakerOn
                  ? AppLocalizations.of(context)!.speaker
                  : AppLocalizations.of(context)!.earpiece,
              active: speakerOn,
              onTap: onSpeaker,
            ),
            if (isVideo)
              _CtrlBtn(
                icon: Icons.flip_camera_ios_rounded,
label: AppLocalizations.of(context)!.flip,
                active: false,
                onTap: () => onFlip(),
              ),
          ],
        ),

        const SizedBox(height: 28),

        // End call button — centred, larger
        GestureDetector(
          onTap: onEnd,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withOpacity(0.5),
                  blurRadius: 20, spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
          ),
        ),
      ],
    ),
  );
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CtrlBtn({
    required this.icon, required this.label,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? Colors.white
                : Colors.white.withOpacity(0.15),
            border: active
                ? null
                : Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(
            icon,
            color: active ? Colors.black : Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}