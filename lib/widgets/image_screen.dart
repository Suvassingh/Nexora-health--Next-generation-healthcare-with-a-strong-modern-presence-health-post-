import 'dart:typed_data';

import 'package:flutter/material.dart';

class FullscreenImage extends StatelessWidget {
  final String imageUrl;

  const FullscreenImage({super.key, required this.imageUrl});

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
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              size: 80,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

// widgets/image_screen.dart  

class FullscreenImageBytes extends StatelessWidget {
  final Uint8List imageBytes;
  const FullscreenImageBytes({super.key, required this.imageBytes});

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
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(imageBytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}