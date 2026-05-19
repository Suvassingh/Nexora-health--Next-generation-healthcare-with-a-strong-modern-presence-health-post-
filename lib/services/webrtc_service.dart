
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';

typedef StreamCallback = void Function(MediaStream stream);

class WebRTCService {
  StreamCallback? onRemoteStream;
  VoidCallback? onCallEnded;

  final _supabase = Supabase.instance.client;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RealtimeChannel? _signalingChannel;

  String? _callId;
  String? _currentUserId;
  bool _disposed = false;

  // Buffer ICE candidates arriving before remoteDescription is set
  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  // TURN credential cache
  Map<String, dynamic>? _turnCache;
  int? _turnExpiryEpoch;

  static const List<Map<String, dynamic>> _defaultStuns = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
  ];

  //  TURN 

  Future<Map<String, dynamic>?> _fetchTurnCredentials() async {
    try {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      if (_turnCache != null &&
          _turnExpiryEpoch != null &&
          now + 10 < _turnExpiryEpoch!) {
        return _turnCache;
      }
      final data = await ApiService.fetchTurnCredentials();
      final urls = <String>[];
      if (data['urls'] is List) {
        urls.addAll((data['urls'] as List).map((e) => e.toString()));
      }
      final expiry = data['expiry'] is int
          ? data['expiry'] as int
          : int.tryParse(data['expiry']?.toString() ?? '');
      final ttl = data['ttl'] is int
          ? data['ttl'] as int
          : int.tryParse(data['ttl']?.toString() ?? '') ?? 3600;
      _turnCache = {
        'username': data['username']?.toString() ?? '',
        'credential': data['credential']?.toString() ?? '',
        'urls': urls,
      };
      _turnExpiryEpoch = expiry ?? (now + ttl);
      debugPrint('[TURN] credentials fetched, expiry=$_turnExpiryEpoch');
      return _turnCache;
    } catch (e, st) {
      debugPrint('[TURN] fetch error: $e\n$st');
      return null;
    }
  }

  Future<Map<String, dynamic>> _buildIceConfig() async {
    final iceServers = List<Map<String, dynamic>>.from(_defaultStuns);
    final turn = await _fetchTurnCredentials();
    if (turn != null) {
      iceServers.add({
        'urls': turn['urls'],
        'username': turn['username'],
        'credential': turn['credential'],
      });
    }
    return {'iceServers': iceServers, 'sdpSemantics': 'unified-plan'};
  }

  //  MEDIA 

  Future<MediaStream> getLocalStream({required bool isVideo}) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo
          ? {'facingMode': 'user', 'width': 1280, 'height': 720}
          : false,
    });
    return _localStream!;
  }

  //  PEER CONNECTION 

  Future<void> _createPeerConnection(bool isVideo) async {
    final iceConfig = await _buildIceConfig();
    debugPrint('[WebRTC] ICE servers count: ${(iceConfig['iceServers'] as List).length}');
    _pc = await createPeerConnection(iceConfig);

    for (var track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty && !_disposed) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null && _callId != null && !_disposed) {
        _pushSignal('ice_candidate', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    _pc!.onIceConnectionState = (state) {
      debugPrint('[WebRTC] ICE state: $state');
      if (!_disposed &&
          (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
              state == RTCIceConnectionState.RTCIceConnectionStateFailed)) {
        onCallEnded?.call();
      }
    };
  }

  Future<void> _setRemoteDescriptionAndDrain(RTCSessionDescription desc) async {
    await _pc!.setRemoteDescription(desc);
    _remoteDescriptionSet = true;
    debugPrint('[WebRTC] remoteDesc set — draining ${_pendingCandidates.length} candidates');
    for (final c in _pendingCandidates) {
      try { await _pc!.addCandidate(c); } catch (e) {
        debugPrint('[WebRTC] buffered candidate error: $e');
      }
    }
    _pendingCandidates.clear();
  }

  //  CALLER 

  Future<void> startAsCallerCall({
    required String callId,
    required String currentUserId,
    required bool isVideo,
  }) async {
    _callId = callId;
    _currentUserId = currentUserId;
    await _createPeerConnection(isVideo);
    _subscribeToSignals(); // BEFORE offer — never miss the answer
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await _pc!.setLocalDescription(offer);
    await _pushSignal('offer', {'sdp': offer.sdp, 'type': offer.type});
    debugPrint('[WebRTC] Caller: offer pushed');
  }

  //  CALLEE 

  Future<void> startAsCalleeCall({
    required String callId,
    required String currentUserId,
    required bool isVideo,
  }) async {
    _callId = callId;
    _currentUserId = currentUserId;
    await _createPeerConnection(isVideo);
    _subscribeToSignals(); // BEFORE polling — buffer ICE, never drop it

    Map<String, dynamic>? offerSignal;
    for (int i = 0; i < 20; i++) {
      final signals = await _supabase
          .from('webrtc_signals')
          .select()
          .eq('call_id', _callId!)
          .eq('type', 'offer')
          .order('created_at', ascending: false)
          .limit(1);
      if (signals.isNotEmpty) { offerSignal = signals[0]; break; }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (offerSignal == null) {
      debugPrint('[WebRTC] Callee: offer not found');
      return;
    }

    final payload = offerSignal['payload'] as Map<String, dynamic>;
    await _setRemoteDescriptionAndDrain(
      RTCSessionDescription(payload['sdp'], payload['type']),
    );
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await _pushSignal('answer', {'sdp': answer.sdp, 'type': answer.type});
    debugPrint('[WebRTC] Callee: answer pushed');
  }

  //  SIGNALING 

  Future<void> _pushSignal(String type, Map<String, dynamic> payload) async {
    await _supabase.from('webrtc_signals').insert({
      'call_id': _callId,
      'sender_id': _currentUserId,
      'type': type,
      'payload': payload,
    });
  }

  void _subscribeToSignals() {
    
    _signalingChannel = _supabase
        .channel('signals:${_callId!}')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'webrtc_signals',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'call_id',
        value: _callId!,
      ),
      callback: (payload) => _handleSignal(payload.newRecord),
    )
        .subscribe((status, [err]) {
      debugPrint('[WebRTC] signaling $status err=$err');
    });
  }

  Future<void> _handleSignal(Map<String, dynamic> signal) async {
    if (_disposed) return;
    if (signal['sender_id'] == _currentUserId) return;

    final type = signal['type'];
    final payload = signal['payload'] as Map<String, dynamic>?;
    if (payload == null) return;
    debugPrint('[WebRTC] received: $type');

    switch (type) {
      case 'answer':
        await _setRemoteDescriptionAndDrain(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );
        break;
      case 'ice_candidate':
        final candidate = RTCIceCandidate(
          payload['candidate'], payload['sdpMid'], payload['sdpMLineIndex'],
        );
        if (_remoteDescriptionSet) {
          try { await _pc?.addCandidate(candidate); }
          catch (e) { debugPrint('[WebRTC] addCandidate error: $e'); }
        } else {
          _pendingCandidates.add(candidate);
        }
        break;
      case 'hangup':
        onCallEnded?.call();
        break;
    }
  }

  //  CONTROLS 

  void setMuted(bool muted) =>
      _localStream?.getAudioTracks().forEach((t) => t.enabled = !muted);

  void setCameraOff(bool off) =>
      _localStream?.getVideoTracks().forEach((t) => t.enabled = !off);

  void setSpeaker(bool speaker) => Helper.setSpeakerphoneOn(speaker);

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) await Helper.switchCamera(tracks[0]);
  }

  Future<void> hangup() async {
    if (!_disposed && _callId != null) await _pushSignal('hangup', {});
    await dispose();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _signalingChannel?.unsubscribe();
    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _pc?.close();
    _pc = null;
    _localStream = null;
    _remoteStream = null;
    _pendingCandidates.clear();
  }
}