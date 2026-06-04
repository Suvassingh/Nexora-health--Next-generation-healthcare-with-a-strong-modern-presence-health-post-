


import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_constants.dart';
import '../services/encryption_service.dart';
import 'image_screen.dart';
import 'video_player.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final List<Map<String, dynamic>> reactions;
  final VoidCallback onLongPress;
  final VoidCallback? onMediaLongPress;
  final encrypt.Key? aesKey;
  

  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.reactions,
    required this.onLongPress,
    required this.aesKey,         
    this.onMediaLongPress,
  });

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final time = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (now.difference(time).inDays > 0) {
        return '${time.day}/${time.month}';
      }
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'sending':
        return const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5));
      case 'sent':
        return const Icon(Icons.check, size: 14, color: Colors.grey);
      case 'delivered':
      case 'seen':
      case 'read':
        return const Icon(Icons.done_all, size: 14, color: Colors.blue);
      case 'error':
        return const Icon(Icons.error_outline, size: 14, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Downloads the encrypted blob and decrypts it in memory.
  Future<Uint8List> _fetchAndDecrypt(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Download failed');
    return EncryptionService.decryptBytes(response.bodyBytes, aesKey!);
  }

  @override
  Widget build(BuildContext context) {
    final isMedia = msg['media_url'] != null;
    final mediaUrl = isMedia ? msg['media_url'] as String : null;
    final mediaType = isMedia ? msg['media_type'] as String? : null;
    final isEncrypted = msg['is_encrypted_media'] == true;
    final isImage = mediaType == 'image';
    final isVideo = mediaType == 'video';
    final timeText = _formatTime(msg['created_at']);
    final status = msg['status'];

    return GestureDetector(
      onLongPress: () {
        if (isMedia) {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            builder: (_) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.emoji_emotions),
                    title: const Text('React'),
                    onTap: () {
                      Navigator.pop(context);
                      onLongPress();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Download / Share'),
                    onTap: () {
                      Navigator.pop(context);
                      onMediaLongPress?.call();
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          onLongPress();
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          top: 4, bottom: 4,
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            //  Encrypted media 
            if (isMedia && isEncrypted && aesKey != null)
              _EncryptedMediaThumbnail(
                url: mediaUrl!,
                isImage: isImage,
                isVideo: isVideo,
                fetchAndDecrypt: _fetchAndDecrypt,
                aesKey: aesKey!,
              ),

            //  Plain (legacy) media 
            if (isMedia && !isEncrypted)
              GestureDetector(
                onTap: () {
                  if (isImage) {
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => FullscreenImage(imageUrl: mediaUrl!)));
                  } else if (isVideo) {
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => FullscreenVideo(videoUrl: mediaUrl!)));
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isImage
                      ? Image.network(mediaUrl!,
                      width: 200, height: 200, fit: BoxFit.cover)
                      : Stack(alignment: Alignment.center, children: [
                    Image.network(mediaUrl!,
                        width: 200, height: 200, fit: BoxFit.cover),
                    const Icon(Icons.play_circle_filled,
                        size: 50, color: Colors.white),
                  ]),
                ),
              ),

            //   Text bubble  
            if (!isMedia && msg['decrypted_content'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? AppConstants.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(msg['decrypted_content'],
                        style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(timeText,
                          style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white70
                                  : Colors.grey.shade600)),
                      const SizedBox(width: 4),
                      if (isMe) _buildStatusIcon(status),
                    ]),
                  ],
                ),
              ),

            //   Media timestamp / status    
            if (isMedia)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(timeText,
                      style:
                      const TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(width: 6),
                  if (isMe) _buildStatusIcon(status),
                ]),
              ),

            //   Reactions  
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Wrap(
                  spacing: 4,
                  children: reactions.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(r['emoji'],
                          style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//   Private widget: handles download → decrypt → display  

class _EncryptedMediaThumbnail extends StatefulWidget {
  final String url;
  final bool isImage;
  final bool isVideo;
  final Future<Uint8List> Function(String) fetchAndDecrypt;
  final encrypt.Key aesKey;

  const _EncryptedMediaThumbnail({
    required this.url,
    required this.isImage,
    required this.isVideo,
    required this.fetchAndDecrypt,
    required this.aesKey,
  });

  @override
  State<_EncryptedMediaThumbnail> createState() =>
      _EncryptedMediaThumbnailState();
}

class _EncryptedMediaThumbnailState extends State<_EncryptedMediaThumbnail> {
  Uint8List? _decryptedBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.fetchAndDecrypt(widget.url);
      if (mounted) setState(() { _decryptedBytes = bytes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 200, height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        width: 200, height: 200,
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock, color: Colors.red),
              const SizedBox(height: 4),
              Text('Decryption failed',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ])),
      );
    }

    return GestureDetector(
      onTap: () {
        if (widget.isImage) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      FullscreenImageBytes(imageBytes: _decryptedBytes!)));
        } else if (widget.isVideo) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      FullscreenVideoBytes(videoBytes: _decryptedBytes!)));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.isImage
            ? Image.memory(_decryptedBytes!,
            width: 200, height: 200, fit: BoxFit.cover)
            : Stack(alignment: Alignment.center, children: [
          // Video: show a grey placeholder + play icon (no thumbnail without extra plugin)
          Container(
              width: 200,
              height: 200,
              color: Colors.grey.shade800,
              child: const Icon(Icons.movie,
                  size: 60, color: Colors.white38)),
          const Icon(Icons.play_circle_filled,
              size: 50, color: Colors.white),
        ]),
      ),
    );
  }
}