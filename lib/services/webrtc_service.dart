// // lib/services/webrtc_service.dart
// // Works in BOTH the patient app and the healthpost (doctor) app.
// // Only import paths differ — adjust the top-level package name accordingly.
//
// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// typedef StreamCallback = void Function(MediaStream stream);
// typedef VoidAsyncCallback = Future<void> Function();
//
// class WebRTCService {
//   // ── public callbacks ───────────────────────────────────────────────────────
//   StreamCallback? onRemoteStream;
//   VoidCallback? onCallEnded;
//
//   // ── private state ──────────────────────────────────────────────────────────
//   final _supabase = Supabase.instance.client;
//
//   RTCPeerConnection? _pc;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;
//   RealtimeChannel? _signalingChannel;
//
//   String? _callId;
//   String? _currentUserId;
//   bool _disposed = false;
//
//   // ── ICE / STUN config ──────────────────────────────────────────────────────
//   static const Map<String, dynamic> _iceConfig = {
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'},
//       {'urls': 'stun:stun1.l.google.com:19302'},
//       {'urls': 'stun:stun2.l.google.com:19302'},
//     ],
//     'sdpSemantics': 'unified-plan',
//   };
//
//   // ──────────────────────────────────────────────────────────────────────────
//   //  LOCAL STREAM
//   // ──────────────────────────────────────────────────────────────────────────
//
//   Future<MediaStream> getLocalStream({required bool isVideo}) async {
//     final constraints = <String, dynamic>{
//       'audio': true,
//       'video': isVideo
//           ? {'facingMode': 'user', 'width': 1280, 'height': 720}
//           : false,
//     };
//     _localStream = await navigator.mediaDevices.getUserMedia(constraints);
//     return _localStream!;
//   }
//
//   // ──────────────────────────────────────────────────────────────────────────
//   //  PEER CONNECTION
//   // ──────────────────────────────────────────────────────────────────────────
//
//   Future<void> _createPeerConnection(bool isVideo) async {
//     _pc = await createPeerConnection(_iceConfig);
//
//     // Add local tracks
//     for (final track in _localStream!.getTracks()) {
//       await _pc!.addTrack(track, _localStream!);
//     }
//
//     // Remote stream
//     _pc!.onTrack = (event) {
//       if (event.streams.isNotEmpty && !_disposed) {
//         _remoteStream = event.streams[0];
//         onRemoteStream?.call(_remoteStream!);
//       }
//     };
//
//     // ICE candidates → push to Supabase
//     _pc!.onIceCandidate = (candidate) {
//       if (candidate.candidate != null && _callId != null && !_disposed) {
//         _pushSignal('ice_candidate', {
//           'candidate': candidate.candidate,
//           'sdpMid': candidate.sdpMid,
//           'sdpMLineIndex': candidate.sdpMLineIndex,
//         });
//       }
//     };
//
//     // Connection state
//     _pc!.onIceConnectionState = (state) {
//       debugPrint('[WebRTC] ICE state: $state');
//       if (!_disposed &&
//           (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
//               state ==
//                   RTCIceConnectionState.RTCIceConnectionStateDisconnected)) {
//         onCallEnded?.call();
//       }
//     };
//   }
//
//   // ──────────────────────────────────────────────────────────────────────────
//   //  CALLER  →  creates offer
//   // ──────────────────────────────────────────────────────────────────────────
//
//   Future<void> startAsCallerCall({
//     required String callId,
//     required String currentUserId,
//     required bool isVideo,
//   }) async {
//     _callId = callId;
//     _currentUserId = currentUserId;
//
//     await _createPeerConnection(isVideo);
//     _subscribeToSignals();
//
//     final offer = await _pc!.createOffer({
//       'offerToReceiveAudio': true,
//       'offerToReceiveVideo': isVideo,
//     });
//     await _pc!.setLocalDescription(offer);
//     await _pushSignal('offer', {'sdp': offer.sdp, 'type': offer.type});
//   }
//
//   // ──────────────────────────────────────────────────────────────────────────
//   //  CALLEE  →  reads offer, creates answer
//   // ──────────────────────────────────────────────────────────────────────────
//
// // In startAsCalleeCall — replace with retry logic:
//   // In startAsCalleeCall — replace with retry logic:
//   Future<void> startAsCalleeCall({
//   required String callId,
//   required String currentUserId,
//   required bool   isVideo,
//   }) async {
//   _callId        = callId;
//   _currentUserId = currentUserId;
//
//   await _createPeerConnection(isVideo);
//   _subscribeToSignals();
//
//   // Retry fetching the offer up to 10 times (caller might not have sent it yet)
//   Map<String, dynamic>? offerSignal;
//   for (int i = 0; i < 10; i++) {
//   final signals = await _supabase
//       .from('webrtc_signals')
//       .select()
//       .eq('call_id', _callId!)
//       .eq('type', 'offer')
//       .order('created_at', ascending: false)
//       .limit(1);
//
//   if (signals.isNotEmpty) {
//   offerSignal = signals[0];
//   break;
//   }
//   debugPrint('[WebRTC] Waiting for offer... attempt ${i + 1}');
//   await Future.delayed(const Duration(milliseconds: 500));
//   }
//
//   if (offerSignal == null) {
//   debugPrint('[WebRTC] No offer found after retries');
//   return;
//   }
//
//   final payload = offerSignal['payload'] as Map<String, dynamic>;
//   await _pc!.setRemoteDescription(RTCSessionDescription(
//   payload['sdp']  as String,
//   payload['type'] as String,
//   ));
//
//   final answer = await _pc!.createAnswer();
//   await _pc!.setLocalDescription(answer);
//   await _pushSignal('answer', {'sdp': answer.sdp, 'type': answer.type});
//   debugPrint('[WebRTC] Answer sent');
//   }
//
//   // ──────────────────────────────────────────────────────────────────────────
//   //  SIGNALING  (Supabase Realtime)
//   // ──────────────────────────────────────────────────────────────────────────
//
//   Future<void> _pushSignal(String type, Map<String, dynamic> payload) async {
//     await _supabase.from('webrtc_signals').insert({
//       'call_id': _callId,
//       'sender_id': _currentUserId,
//       'type': type,
//       'payload': payload,
//     });
//   }
//
//   void _subscribeToSignals() {
//     // unique channel name → avoids conflicts between caller and callee
//     final channel = 'signals:${_callId!}:$_currentUserId';
//
//     _signalingChannel = _supabase
//         .channel(channel)
//         .onPostgresChanges(
//           event: PostgresChangeEvent.insert,
//           schema: 'public',
//           table: 'webrtc_signals',
//           filter: PostgresChangeFilter(
//             type: PostgresChangeFilterType.eq,
//             column: 'call_id',
//             value: _callId!,
//           ),
//           callback: (payload) => _handleSignal(payload.newRecord),
//         )
//         .subscribe((status, [err]) {
//           debugPrint('[WebRTC] Signaling channel: $status $err');
//         });
//   }
//
//   Future<void> _handleSignal(Map<String, dynamic> signal) async {
//     if (_disposed) return;
//     if (signal['sender_id'] == _currentUserId) return; // ignore own
//
//     final type = signal['type'] as String;
//     final payload = signal['payload'] as Map<String, dynamic>;
//
//     switch (type) {
//       case 'answer':
//         await _pc?.setRemoteDescription(
//           RTCSessionDescription(
//             payload['sdp'] as String,
//             payload['type'] as String,
//           ),
//         );
//         break;
//
//       case 'ice_candidate':
//         await _pc?.addCandidate(
//           RTCIceCandidate(
//             payload['candidate'] as String,
//             payload['sdpMid'] as String?,
//             payload['sdpMLineIndex'] as int?,
//           ),
//         );
//         break;
//
//       case 'hangup':
//         onCallEnded?.call();
//         break;
//     }
//   }
//
//   // ──────────────────────────────────────────────────────────────────────────
//   //  CONTROLS
//   // ──────────────────────────────────────────────────────────────────────────
//
//   void setMuted(bool muted) =>
//       _localStream?.getAudioTracks().forEach((t) => t.enabled = !muted);
//
//   void setCameraOff(bool off) =>
//       _localStream?.getVideoTracks().forEach((t) => t.enabled = !off);
//
//   void setSpeaker(bool speaker) => Helper.setSpeakerphoneOn(speaker);
//
//   Future<void> switchCamera() async {
//     final tracks = _localStream?.getVideoTracks();
//     if (tracks != null && tracks.isNotEmpty) {
//       await Helper.switchCamera(tracks[0]);
//     }
//   }
//
//   // ──────────────────────────────────────────────────────────────────────────
//   //  HANGUP / DISPOSE
//   // ──────────────────────────────────────────────────────────────────────────
//
//   Future<void> hangup() async {
//     if (!_disposed && _callId != null) {
//       await _pushSignal('hangup', {});
//     }
//     await dispose();
//   }
//
//   Future<void> dispose() async {
//     if (_disposed) return;
//     _disposed = true;
//     _signalingChannel?.unsubscribe();
//     _localStream?.getTracks().forEach((t) => t.stop());
//     await _localStream?.dispose();
//     await _remoteStream?.dispose();
//     await _pc?.close();
//     _pc = null;
//     _localStream = null;
//     _remoteStream = null;
//   }
// }





// lib/services/webrtc_service.dart
// Works in BOTH the patient app and the healthpost (doctor) app.
// Only import paths differ — adjust the top-level package name accordingly.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef StreamCallback  = void Function(MediaStream stream);
typedef VoidAsyncCallback = Future<void> Function();

class WebRTCService {
  // ── public callbacks ───────────────────────────────────────────────────────
  StreamCallback?       onRemoteStream;
  VoidCallback?         onCallEnded;

  // ── private state ──────────────────────────────────────────────────────────
  final _supabase = Supabase.instance.client;

  RTCPeerConnection? _pc;
  MediaStream?       _localStream;
  MediaStream?       _remoteStream;
  RealtimeChannel?   _signalingChannel;

  String? _callId;
  String? _currentUserId;
  bool    _disposed = false;

  // ── ICE / STUN config ──────────────────────────────────────────────────────
  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // ──────────────────────────────────────────────────────────────────────────
  //  LOCAL STREAM
  // ──────────────────────────────────────────────────────────────────────────

  Future<MediaStream> getLocalStream({required bool isVideo}) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': isVideo
          ? {'facingMode': 'user', 'width': 1280, 'height': 720}
          : false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    return _localStream!;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PEER CONNECTION
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _createPeerConnection(bool isVideo) async {
    _pc = await createPeerConnection(_iceConfig);

    // Add local tracks
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    // Remote stream
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty && !_disposed) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };

    // ICE candidates → push to Supabase
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null && _callId != null && !_disposed) {
        _pushSignal('ice_candidate', {
          'candidate':     candidate.candidate,
          'sdpMid':        candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // Connection state
    _pc!.onIceConnectionState = (state) {
      debugPrint('[WebRTC] ICE state: $state');
      if (!_disposed &&
          (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
              state == RTCIceConnectionState.RTCIceConnectionStateDisconnected)) {
        onCallEnded?.call();
      }
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  CALLER  →  creates offer
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> startAsCallerCall({
    required String callId,
    required String currentUserId,
    required bool   isVideo,
  }) async {
    _callId        = callId;
    _currentUserId = currentUserId;

    await _createPeerConnection(isVideo);
    _subscribeToSignals();

    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await _pc!.setLocalDescription(offer);
    await _pushSignal('offer', {'sdp': offer.sdp, 'type': offer.type});
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  CALLEE  →  reads offer, creates answer
  // ──────────────────────────────────────────────────────────────────────────

// In startAsCalleeCall — replace with retry logic:
  Future<void> startAsCalleeCall({
    required String callId,
    required String currentUserId,
    required bool   isVideo,
  }) async {
    _callId        = callId;
    _currentUserId = currentUserId;

    await _createPeerConnection(isVideo);
    _subscribeToSignals();

    // Retry fetching the offer up to 10 times (caller might not have sent it yet)
    Map<String, dynamic>? offerSignal;
    for (int i = 0; i < 10; i++) {
      final signals = await _supabase
          .from('webrtc_signals')
          .select()
          .eq('call_id', _callId!)
          .eq('type', 'offer')
          .order('created_at', ascending: false)
          .limit(1);

      if (signals.isNotEmpty) {
        offerSignal = signals[0];
        break;
      }
      debugPrint('[WebRTC] Waiting for offer... attempt ${i + 1}');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (offerSignal == null) {
      debugPrint('[WebRTC] No offer found after retries');
      return;
    }

    final payload = offerSignal['payload'] as Map<String, dynamic>;
    await _pc!.setRemoteDescription(RTCSessionDescription(
      payload['sdp']  as String,
      payload['type'] as String,
    ));

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await _pushSignal('answer', {'sdp': answer.sdp, 'type': answer.type});
    debugPrint('[WebRTC] Answer sent');
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  SIGNALING  (Supabase Realtime)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _pushSignal(String type, Map<String, dynamic> payload) async {
    await _supabase.from('webrtc_signals').insert({
      'call_id':   _callId,
      'sender_id': _currentUserId,
      'type':      type,
      'payload':   payload,
    });
  }

  void _subscribeToSignals() {
    // unique channel name → avoids conflicts between caller and callee
    final channel = 'signals:${_callId!}:$_currentUserId';

    _signalingChannel = _supabase
        .channel(channel)
        .onPostgresChanges(
      event:  PostgresChangeEvent.insert,
      schema: 'public',
      table:  'webrtc_signals',
      filter: PostgresChangeFilter(
        type:   PostgresChangeFilterType.eq,
        column: 'call_id',
        value:  _callId!,
      ),
      callback: (payload) => _handleSignal(payload.newRecord),
    )
        .subscribe((status, [err]) {
      debugPrint('[WebRTC] Signaling channel: $status $err');
    });
  }

  Future<void> _handleSignal(Map<String, dynamic> signal) async {
    if (_disposed) return;
    if (signal['sender_id'] == _currentUserId) return; // ignore own

    final type    = signal['type'] as String;
    final payload = signal['payload'] as Map<String, dynamic>;

    switch (type) {
      case 'answer':
        await _pc?.setRemoteDescription(RTCSessionDescription(
          payload['sdp']  as String,
          payload['type'] as String,
        ));
        break;

      case 'ice_candidate':
        await _pc?.addCandidate(RTCIceCandidate(
          payload['candidate']     as String,
          payload['sdpMid']        as String?,
          payload['sdpMLineIndex'] as int?,
        ));
        break;

      case 'hangup':
        onCallEnded?.call();
        break;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  CONTROLS
  // ──────────────────────────────────────────────────────────────────────────

  void setMuted(bool muted) =>
      _localStream?.getAudioTracks().forEach((t) => t.enabled = !muted);

  void setCameraOff(bool off) =>
      _localStream?.getVideoTracks().forEach((t) => t.enabled = !off);

  void setSpeaker(bool speaker) => Helper.setSpeakerphoneOn(speaker);

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      await Helper.switchCamera(tracks[0]);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  HANGUP / DISPOSE
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> hangup() async {
    if (!_disposed && _callId != null) {
      await _pushSignal('hangup', {});
    }
    await dispose();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _signalingChannel?.unsubscribe();
    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _pc?.close();
    _pc           = null;
    _localStream  = null;
    _remoteStream = null;
  }
}