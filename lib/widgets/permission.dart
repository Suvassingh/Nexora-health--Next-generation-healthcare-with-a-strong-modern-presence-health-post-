import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCallPermissions({bool isVideo = true}) async {
  final mic = await Permission.microphone.request();
  if (!isVideo) return mic.isGranted;
  final cam = await Permission.camera.request();
  return mic.isGranted && cam.isGranted;
}