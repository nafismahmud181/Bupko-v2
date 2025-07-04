import 'package:bupko_v2/book_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../screens/epub_reader_screen.dart';
import '../services/epub_downloader.dart';
import 'package:bupko_v2/models/book.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return _buildAuthPrompt();
        }
        return _LibraryTabView(uid: user.uid);
      },
    );
  }

  Widget _buildAuthPrompt() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Library Awaits',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your personal collection',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTabView extends StatelessWidget {
  final String uid;
  const _LibraryTabView({required this.uid});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'My Library',
            style: TextStyle(
              color: Color(0xFF1D1D1F),
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF6B7280),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'My Books'),
                  Tab(text: 'Favorites'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _MyBooksList(),
            _FavoritesList(),
          ],
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final favoritesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: favoritesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No Favorites Yet',
            subtitle: 'Books you favorite will appear here',
          );
        }

        final books = snapshot.data!.docs;
        return _buildBooksGrid(books, user.uid);
      },
    );
  }

  Widget _buildBooksGrid(List<QueryDocumentSnapshot> books, String uid) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = Book.fromJson(books[index].data() as Map<String, dynamic>);
          final categoryName = books[index].reference.parent.parent?.id ?? '';
          
          return _BookCard(
            book: book,
            categoryName: categoryName,
            isFavorite: true,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MyBooksList extends StatefulWidget {
  const _MyBooksList();

  @override
  State<_MyBooksList> createState() => _MyBooksListState();
}

class _MyBooksListState extends State<_MyBooksList> {
  final Map<String, double> _downloadProgress = {};
  Stream<QuerySnapshot>? _libraryStream;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid != null) {
      _initializeStream();
    }
  }

  void _initializeStream() {
    _libraryStream = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid!)
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
        SnackBar(
          content: const Text('No download link available for this book.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _downloadProgress[docId] = 0.0;
    });

    final downloader = EpubDownloader();
    try {
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download completed!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _downloadProgress.remove(docId);
      });
    }
  }

  Future<void> _deleteBook(String docId, String? localPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Book',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to delete this book from your library and device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
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
          .doc(_uid!)
          .collection('library')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _refreshLibrary,
      color: const Color(0xFF007AFF),
      child: StreamBuilder<QuerySnapshot>(
        stream: _libraryStream,
        builder: (context, snapshot) {
          if (_libraryStream == null) {
            return _buildLoadingGrid();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingGrid();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final books = snapshot.data!.docs;
          return _buildBooksGrid(books);
        },
      ),
    );
  }

  Widget _buildBooksGrid(List<QueryDocumentSnapshot> books) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final data = books[index].data() as Map<String, dynamic>;
          final docId = books[index].id;
          
          return _LibraryBookCard(
            data: data,
            docId: docId,
            downloadProgress: _downloadProgress[docId],
            onDownload: () => _downloadBook(data, docId),
            onDelete: () => _deleteBook(docId, data['localPath']),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Library is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building your collection by adding books',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final String categoryName;
  final bool isFavorite;

  const _BookCard({
    required this.book,
    required this.categoryName,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailPage(
              book: book,
              categoryName: categoryName,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: book.imageSRC.isNotEmpty
                      ? Image.network(
                          book.imageSRC,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // <-- Added to prevent overflow
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Icon(
        Icons.auto_stories_rounded,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }
}

class _LibraryBookCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final double? downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _LibraryBookCard({
    required this.data,
    required this.docId,
    this.downloadProgress,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final localPath = data['localPath'] as String?;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: data['imageSRC'] != null
                        ? Image.network(
                            data['imageSRC'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (downloadProgress != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: LinearProgressIndicator(
                        value: downloadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // <-- Added to prevent overflow
              children: [
                Text(
                  data['title'] ?? 'Unknown Title',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data['author'] ?? 'Unknown Author',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: FutureBuilder<bool>(
              future: _fileExists(localPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 32,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                
                if (downloadProgress != null) {
                  return Container(
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '${(downloadProgress! * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  );
                }
                
                final fileExists = snapshot.data ?? false;
                return SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: fileExists
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EpubReaderScreen(epubPath: localPath!),
                              ),
                            );
                          }
                        : onDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fileExists ? const Color(0xFF007AFF) : Colors.grey[200],
                      foregroundColor: fileExists ? Colors.white : Colors.grey[600],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      fileExists ? 'Read' : 'Download',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _fileExists(String? path) async {
    if (path == null) return false;
    return File(path).exists();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Icon(
        Icons.auto_stories_rounded,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }
}