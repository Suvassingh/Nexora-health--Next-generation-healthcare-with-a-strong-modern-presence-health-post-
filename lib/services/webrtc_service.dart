
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

  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  Map<String, dynamic>? _turnCache;
  int? _turnExpiryEpoch;

  static const List<Map<String, dynamic>> _defaultStuns = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
  ];

  // ---------- TURN helpers ----------
  String _sanitizeTurnUrl(String raw) {
    while (raw.startsWith('turn:turn:')) raw = raw.substring(5);
    while (raw.startsWith('turns:turns:')) raw = raw.substring(6);
    if (!raw.startsWith('turn:') && !raw.startsWith('turns:') && !raw.startsWith('stun:')) {
      raw = 'turn:$raw';
    }
    return raw;
  }

  Future<Map<String, dynamic>?> _fetchTurnCredentials() async {
    try {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      if (_turnCache != null && _turnExpiryEpoch != null && now + 10 < _turnExpiryEpoch!) {
        return _turnCache;
      }
      final data = await ApiService.fetchTurnCredentials();
      List<String> urls = [];
      if (data['urls'] is List) {
        urls = (data['urls'] as List).map((e) => _sanitizeTurnUrl(e.toString())).toList();
      }
      if (urls.isEmpty) {
        debugPrint('[TURN] No valid TURN URLs – using STUN only');
        return null;
      }
      final expiry = data['expiry'] is int ? data['expiry'] : int.tryParse(data['expiry']?.toString() ?? '');
      final ttl = data['ttl'] is int ? data['ttl'] : int.tryParse(data['ttl']?.toString() ?? '') ?? 3600;
      _turnCache = {
        'username': data['username']?.toString() ?? '',
        'credential': data['credential']?.toString() ?? '',
        'urls': urls,
      };
      _turnExpiryEpoch = expiry ?? (now + ttl);
      debugPrint('[TURN] credentials fetched, expiry=$_turnExpiryEpoch, urls=$urls');
      return _turnCache;
    } catch (e) {
      debugPrint('[TURN] fetch error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _buildIceConfig() async {
    final iceServers = List<Map<String, dynamic>>.from(_defaultStuns);
    final turn = await _fetchTurnCredentials();
    if (turn != null && turn['urls'] is List && (turn['urls'] as List).isNotEmpty) {
      iceServers.add({
        'urls': turn['urls'],
        'username': turn['username'],
        'credential': turn['credential'],
      });
    }
    return {'iceServers': iceServers, 'sdpSemantics': 'unified-plan'};
  }

  //  Media 
  Future<MediaStream> getLocalStream({required bool isVideo}) async {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((t) => t.stop());
      await _localStream!.dispose();
      _localStream = null;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo
          ? {'facingMode': 'user', 'width': 1280, 'height': 720}
          : false,
    });
    return _localStream!;
  }

  //  Peer connection 
  Future<void> _createPeerConnection(bool isVideo) async {
    await _pc?.close();
    _pc = null;
    _remoteDescriptionSet = false;
    _pendingCandidates.clear();

    final iceConfig = await _buildIceConfig();
    debugPrint('[WebRTC] ICE servers count: ${(iceConfig['iceServers'] as List).length}');

    try {
      _pc = await createPeerConnection(iceConfig);
      if (_pc == null) throw Exception('RTCPeerConnection creation returned null');
      await Future.delayed(Duration.zero);
    } catch (e) {
      debugPrint('[WebRTC] createPeerConnection failed: $e');
      rethrow;
    }

    if (_localStream == null) {
      throw StateError('[WebRTC] _localStream is null – call getLocalStream() first');
    }
    for (final track in _localStream!.getTracks()) {
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
      if (!_disposed && (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed)) {
        onCallEnded?.call();
      }
    };

    _pc!.onConnectionState = (state) {
      debugPrint('[WebRTC] connection state: $state');
      if (!_disposed && state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onCallEnded?.call();
      }
    };
  }

  Future<void> _setRemoteDescriptionAndDrain(RTCSessionDescription desc) async {
    if (_pc == null) throw Exception('Peer connection is null');
    await _pc!.setRemoteDescription(desc);
    _remoteDescriptionSet = true;
    debugPrint('[WebRTC] remoteDesc set — draining ${_pendingCandidates.length} candidates');
    for (final c in _pendingCandidates) {
      await _pc!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  //  Caller 
  Future<void> startAsCallerCall({
    required String callId,
    required String currentUserId,
    required bool isVideo,
  }) async {
    _callId = callId;
    _currentUserId = currentUserId;

    await _createPeerConnection(isVideo);
    _subscribeToSignals();

    if (_pc == null) throw Exception('Peer connection is null after creation');
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await _pc!.setLocalDescription(offer);
    await _pushSignal('offer', {'sdp': offer.sdp, 'type': offer.type});
    debugPrint('[WebRTC] Caller: offer pushed');
  }

  //  Callee 
  Future<void> startAsCalleeCall({
    required String callId,
    required String currentUserId,
    required bool isVideo,
  }) async {
    _callId = callId;
    _currentUserId = currentUserId;

    await _createPeerConnection(isVideo);
    _subscribeToSignals();

    // Poll for offer (max 30 sec)
    Map<String, dynamic>? offerSignal;
    for (int i = 0; i < 60; i++) {
      if (_disposed) return;
      final signals = await _supabase
          .from('webrtc_signals')
          .select()
          .eq('call_id', _callId!)
          .eq('type', 'offer')
          .order('created_at', ascending: false)
          .limit(1);
      if (signals.isNotEmpty) {
        offerSignal = signals[0];
        debugPrint('[WebRTC] Callee: offer found after ${i * 500}ms');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (offerSignal == null) {
      debugPrint('[WebRTC] Callee: offer not found after 30 seconds');
      onCallEnded?.call();
      return;
    }

    final payload = offerSignal['payload'] as Map<String, dynamic>;
    await _setRemoteDescriptionAndDrain(
      RTCSessionDescription(payload['sdp'], payload['type']),
    );
    if (_pc == null) throw Exception('Peer connection is null');
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await _pushSignal('answer', {'sdp': answer.sdp, 'type': answer.type});
    debugPrint('[WebRTC] Callee: answer pushed');
  }

  //  Signaling 
  Future<void> _pushSignal(String type, Map<String, dynamic> payload) async {
    if (_pc == null) return;
    try {
      await _supabase.from('webrtc_signals').insert({
        'call_id': _callId,
        'sender_id': _currentUserId,
        'type': type,
        'payload': payload,
      });
    } catch (e) {
      debugPrint('[WebRTC] pushSignal error ($type): $e');
    }
  }

  void _subscribeToSignals() {
    _signalingChannel?.unsubscribe();
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
        .subscribe();
  }

  Future<void> _handleSignal(Map<String, dynamic> signal) async {
    if (_disposed) return;
    if (signal['sender_id'] == _currentUserId) return;

    final type = signal['type'] as String?;
    final payload = signal['payload'] as Map<String, dynamic>?;
    if (type == null || payload == null) return;

    switch (type) {
      case 'answer':
        await _setRemoteDescriptionAndDrain(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );
        break;
      case 'ice_candidate':
        final candidateStr = payload['candidate'] as String?;
        if (candidateStr == null || candidateStr.isEmpty) return;
        final candidate = RTCIceCandidate(
          candidateStr,
          payload['sdpMid'] as String?,
          payload['sdpMLineIndex'] as int?,
        );
        if (_remoteDescriptionSet) {
          await _pc?.addCandidate(candidate);
        } else {
          _pendingCandidates.add(candidate);
        }
        break;
      case 'hangup':
        onCallEnded?.call();
        break;
    }
  }

  //  Controls  
  void setMuted(bool muted) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !muted);
  }

  void setCameraOff(bool off) {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !off);
  }

  void setSpeaker(bool speaker) {
    try {
      Helper.setSpeakerphoneOn(speaker);
    } catch (e) {
      debugPrint('[WebRTC] setSpeaker error: $e');
    }
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      try {
        await Helper.switchCamera(tracks[0]);
      } catch (e) {
        debugPrint('[WebRTC] switchCamera error: $e');
      }
    }
  }

  //  Teardown  
  Future<void> hangup() async {
    if (_disposed) return;
    if (_callId != null) await _pushSignal('hangup', {});
    await dispose();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _signalingChannel?.unsubscribe();
      _localStream?.getTracks().forEach((t) => t.stop());
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      await _pc?.close();
    } finally {
      _pc = null;
      _localStream = null;
      _remoteStream = null;
      _pendingCandidates.clear();
      _disposed = false;
    }
  }
}