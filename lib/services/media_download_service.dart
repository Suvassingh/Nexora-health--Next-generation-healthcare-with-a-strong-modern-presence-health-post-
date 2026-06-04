import 'dart:io';
import 'package:dio/dio.dart';
 import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class MediaDownloadService {
  static Future<void> downloadAndSave(String url, String filename) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        Get.snackbar('Permission denied', 'Cannot save media without storage permission');
        return;
      }
    }

    try {
      final Dio dio = Dio();
      final Directory directory = await getApplicationDocumentsDirectory();
      final String savePath = '${directory.path}/$filename';

      await dio.download(url, savePath);

      Get.snackbar('Downloaded', 'Media saved to $savePath');
    } catch (e) {
      Get.snackbar('Error', 'Download failed: $e');
    }
  }
}