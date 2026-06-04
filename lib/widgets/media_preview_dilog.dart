import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewDialog extends StatefulWidget {
  final File file;
  final String mediaType;
  final VoidCallback onConfirm;

  const MediaPreviewDialog({
    super.key,
    required this.file,
    required this.mediaType,
    required this.onConfirm,
  });

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _videoController = VideoPlayerController.file(widget.file);
      _videoController.initialize().then((_) {
        setState(() => _isInitialized = true);
        _videoController.play(); // autoplay preview
        _videoController.setLooping(true);
      });
    }
  }

  @override
  void dispose() {
    if (widget.mediaType == 'video') {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Preview ${widget.mediaType}'),
      content: Container(
        width: double.maxFinite,
        height: 300,
        child: widget.mediaType == 'image'
            ? Image.file(widget.file, fit: BoxFit.contain)
            : _isInitialized
            ? AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        )
            : const Center(child: CircularProgressIndicator()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm();
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}