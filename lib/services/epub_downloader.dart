import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class EpubDownloader {
  Dio dio = Dio();

  Future<String?> downloadEpub(
      String url, Function(int, int) onProgress, Map<String, dynamic> bookData) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = "${appDocDir.path}/book_${bookData['id'] ?? DateTime.now().millisecondsSinceEpoch}.epub";

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          onProgress(received, total);
        },
      );

      // Save book metadata to Firestore under user's library
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final libraryRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('library');
        await libraryRef.doc(bookData['id']).set({
          ...bookData,
          'downloaded': true,
          'localPath': filePath,
          'downloadedAt': FieldValue.serverTimestamp(),
        });
      }

      return filePath;
    } catch (e) {
      // print("Download error: $e");
      return null;
    }
  }
} 