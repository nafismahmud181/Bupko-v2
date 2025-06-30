import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../screens/epub_reader_screen.dart';
import '../services/epub_downloader.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('Please log in to view your library.'));
        }
        return _LibraryContent(uid: user.uid);
      },
    );
  }
}

class _LibraryContent extends StatefulWidget {
  final String uid;
  const _LibraryContent({required this.uid});

  @override
  State<_LibraryContent> createState() => _LibraryContentState();
}

class _LibraryContentState extends State<_LibraryContent> {
  final Map<String, double> _downloadProgress = {};
  Stream<QuerySnapshot>? _libraryStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _libraryStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('library')
        .snapshots();
  }

  Future<void> _refreshLibrary() async {
    setState(() {
      _libraryStream = null;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _initializeStream();
      });
    }
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('library')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: RefreshIndicator(
        onRefresh: _refreshLibrary,
        child: StreamBuilder<QuerySnapshot>(
          stream: _libraryStream,
          builder: (context, snapshot) {
            if (_libraryStream == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No books in your library yet.'));
            }
            final books = snapshot.data!.docs;
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  title: Text(
                    data['title'] ?? 'Unknown Title',
                    style: const TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 32,
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
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _deleteBook(docId, localPath),
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
      ),
    );
  }
}
