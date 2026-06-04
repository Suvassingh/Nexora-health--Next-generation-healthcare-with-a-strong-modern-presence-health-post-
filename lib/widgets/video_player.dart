import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideo extends StatefulWidget {
  final String videoUrl;

  const FullscreenVideo({super.key, required this.videoUrl});

  @override
  State<FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<FullscreenVideo> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      setState(() => _initialized = true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _initialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(
          _initialized && _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}



class FullscreenVideoBytes extends StatefulWidget {
  final Uint8List videoBytes;
  const FullscreenVideoBytes({super.key, required this.videoBytes});

  @override
  State<FullscreenVideoBytes> createState() => _FullscreenVideoBytesState();
}

class _FullscreenVideoBytesState extends State<FullscreenVideoBytes> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  File? _tempFile;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // video_player needs a file/URL; write decrypted bytes to a temp file
    final dir = await getTemporaryDirectory();
    _tempFile = File('${dir.path}/tmp_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
    await _tempFile!.writeAsBytes(widget.videoBytes);

    _controller = VideoPlayerController.file(_tempFile!);
    await _controller!.initialize();
    _controller!.play();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tempFile?.delete().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _initialized
            ? AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!))
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _initialized
          ? FloatingActionButton(
        onPressed: () => setState(() {
          _controller!.value.isPlaying
              ? _controller!.pause()
              : _controller!.play();
        }),
        child: Icon(_controller!.value.isPlaying
            ? Icons.pause
            : Icons.play_arrow),
      )
          : null,
    );
  }
}