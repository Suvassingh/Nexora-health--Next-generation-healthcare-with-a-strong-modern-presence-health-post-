


import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

enum CallState { ringing, connected, ended }

class LiveKitCallScreen extends StatefulWidget {
  final String livekitUrl;
  final String token;
  final String roomName;
  final String remoteUserName;
  final bool isVideo;
  final bool isCaller;

  const LiveKitCallScreen({
    super.key,
    required this.livekitUrl,
    required this.token,
    required this.roomName,
    required this.remoteUserName,
    required this.isVideo,
    this.isCaller = true,
  });

  @override
  State<LiveKitCallScreen> createState() => _LiveKitCallScreenState();
}

class _LiveKitCallScreenState extends State<LiveKitCallScreen> {
  late Room _room;
  EventsListener<RoomEvent>? _roomListener;

  bool _micOn = true;
  bool _camOn = true;
  bool _speakerOn = true;
  bool _isDisposing = false; 
  CallState _callState = CallState.ringing;
  String _statusMessage = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _connect();
  }
  Future<void> _connect() async {
    _room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );

    _roomListener = _room.createListener();

    _roomListener!.on<ParticipantConnectedEvent>((_) {
      if (mounted && !_isDisposing) {
        setState(() {
          _callState = CallState.connected;
          _statusMessage = '';
        });
      }
    });

    _roomListener!.on<TrackPublishedEvent>((_) {
      if (mounted && !_isDisposing) setState(() {});
    });

    _roomListener!.on<TrackSubscribedEvent>((_) {
      if (mounted && !_isDisposing) {
        setState(() {
          _callState = CallState.connected;
          _statusMessage = '';
        });
      }
    });

    _roomListener!.on<ParticipantDisconnectedEvent>((_) {
      if (mounted && !_isDisposing) _safeEndCall();
    });

    _roomListener!.on<RoomDisconnectedEvent>((_) {
      if (mounted && !_isDisposing) _safeEndCall();
    });

    try {
      await _room.connect(widget.livekitUrl, widget.token);
      if (!mounted) return;

      await _room.localParticipant?.setMicrophoneEnabled(true);
      await _room.localParticipant?.setCameraEnabled(widget.isVideo);
      if (!mounted) return;

      if (_room.remoteParticipants.isNotEmpty) {
        setState(() {
          _callState = CallState.connected;
          _statusMessage = '';
        });
      } else if (widget.isCaller) {
        setState(() => _statusMessage = 'Ringing...');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _safeEndCall() async {
    if (_isDisposing) return;
    _isDisposing = true;

    // Dispose listener first — stops all incoming RoomDisconnectedEvent callbacks
    await _roomListener?.dispose();
    _roomListener = null;

    // Disconnect room cleanly BEFORE ending callkit UI
    try {
      await _room.disconnect();
      _room.dispose();
    } catch (_) {}

    // End callkit notification — use the same ID passed to showCallkitIncoming
    await FlutterCallkitIncoming.endCall(widget.roomName);

    if (mounted) Navigator.of(context).pop();
  }


  @override
  void dispose() {
    _isDisposing = true;
    _roomListener?.dispose();
    _roomListener = null;
    _room.disconnect().whenComplete(() {
      try { _room.dispose(); } catch (_) {}
    });
    FlutterCallkitIncoming.endCall(widget.roomName);
    super.dispose();
  }

  void _toggleMic() {
    if (_isDisposing) return;
    setState(() {
      _micOn = !_micOn;
      _room.localParticipant?.setMicrophoneEnabled(_micOn);
    });
  }

  void _toggleCam() {
    if (_isDisposing) return;
    setState(() {
      _camOn = !_camOn;
      _room.localParticipant?.setCameraEnabled(_camOn);
    });
  }

  void _toggleSpeaker() {
    if (_isDisposing) return;
    setState(() {
      _speakerOn = !_speakerOn;
      Hardware.instance.setSpeakerphoneOn(_speakerOn);
    });
  }

  void _endCall() {
    _safeEndCall();
  }

  VideoTrack? _firstVideoTrack(Participant? participant) {
    if (participant == null) return null;
    final pubs = participant.videoTrackPublications;
    if (pubs.isEmpty) return null;
    final track = pubs.first.track;
    return track is VideoTrack ? track : null;
  }

  @override
  Widget build(BuildContext context) {
    final remoteParticipants = _room.remoteParticipants.values.toList();
    final remoteParticipant =
    remoteParticipants.isNotEmpty ? remoteParticipants.first : null;

    final remoteVideoTrack = _firstVideoTrack(remoteParticipant);
    final localVideoTrack = _firstVideoTrack(_room.localParticipant);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (widget.isVideo &&
                _callState == CallState.connected &&
                remoteVideoTrack != null)
              Positioned.fill(child: VideoTrackRenderer(remoteVideoTrack)),

            if (!widget.isVideo || _callState == CallState.ringing)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueGrey,
                      child: Text(
                        widget.remoteUserName.isNotEmpty
                            ? widget.remoteUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.remoteUserName,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

            if (widget.isVideo &&
                _callState == CallState.connected &&
                localVideoTrack != null)
              Positioned(
                top: 50,
                right: 20,
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: VideoTrackRenderer(localVideoTrack),
                ),
              ),

            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: _micOn ? Icons.mic : Icons.mic_off,
                    onPressed: _toggleMic,
                    color: _micOn ? Colors.white : Colors.red,
                  ),
                  if (widget.isVideo)
                    _ControlButton(
                      icon: _camOn ? Icons.videocam : Icons.videocam_off,
                      onPressed: _toggleCam,
                      color: _camOn ? Colors.white : Colors.red,
                    ),
                  _ControlButton(
                    icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                    onPressed: _toggleSpeaker,
                    color: Colors.white,
                  ),
                  _ControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    color: Colors.red,
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: color.withOpacity(0.3),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}