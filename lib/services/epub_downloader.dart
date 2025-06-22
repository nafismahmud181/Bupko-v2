import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class EpubDownloader {
  Dio dio = Dio();

  Future<String?> downloadEpub(
      String url, Function(int, int) onProgress) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = "${appDocDir.path}/book.epub";

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          onProgress(received, total);
        },
      );

      return filePath;
    } catch (e) {
      // print("Download error: $e");
      return null;
    }
  }
} 