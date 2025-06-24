import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../screens/epub_reader_screen.dart';
import '../services/epub_downloader.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final String? _uid;
  Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<bool> _fileExists(String? path) async {
    if (path == null) return false;
    return File(path).exists();
  }

  Future<void> _downloadBook(Map<String, dynamic> data, String docId) async {
    if (data['epubHREF'] == null || data['epubHREF'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No download link available for this book.')),
      );
      return;
    }
    setState(() {
      _downloadProgress[docId] = 0.0;
    });
    final downloader = EpubDownloader();
    await downloader.downloadEpub(
      data['epubHREF'],
      (received, total) {
        if (total != -1) {
          setState(() {
            _downloadProgress[docId] = received / total;
          });
        }
      },
      {
        'id': docId,
        'title': data['title'],
        'author': data['author'],
        'language': data['language'],
        'imageSRC': data['imageSRC'],
        'readonlineHREF': data['readonlineHREF'],
        'epubHREF': data['epubHREF'],
      },
    );
    setState(() {
      _downloadProgress.remove(docId);
    });
  }

  Future<void> _deleteBook(String docId, String? localPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book from your library and device?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      if (_uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('library')
            .doc(docId)
            .delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Center(child: Text('Please log in to view your library.'));
    }
    final libraryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('library');
    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: StreamBuilder<QuerySnapshot>(
        stream: libraryRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No books in your library yet.'));
          }
          final books = snapshot.data!.docs;
          return ListView.separated(
            itemCount: books.length,
            separatorBuilder: (context, i) => const Divider(),
            itemBuilder: (context, i) {
              final data = books[i].data() as Map<String, dynamic>;
              final docId = books[i].id;
              final localPath = data['localPath'] as String?;
              return ListTile(
                leading: data['imageSRC'] != null
                    ? Image.network(data['imageSRC'], width: 50, height: 70, fit: BoxFit.cover)
                    : const Icon(Icons.book, size: 50),
                title: Text(data['title'] ?? 'Unknown Title'),
                subtitle: Text(data['author'] ?? ''),
                trailing: FutureBuilder<bool>(
                  future: _fileExists(localPath),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (_downloadProgress.containsKey(docId)) {
                      return SizedBox(
                        width: 80,
                        child: LinearProgressIndicator(value: _downloadProgress[docId]),
                      );
                    }
                    final exists = snap.data ?? false;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 25,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (exists) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EpubReaderScreen(epubPath: localPath!),
                                  ),
                                );
                              } else {
                                await _downloadBook(data, docId);
                              }
                            },
                            child: Text(exists ? 'Read' : 'Download'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 25,
                          child: ElevatedButton(
                            onPressed: () => _deleteBook(docId, localPath),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
