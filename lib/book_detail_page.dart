import 'dart:convert';
import 'dart:io';

import 'package:bupko_v2/models/book.dart';
import 'package:bupko_v2/screens/epub_reader_screen.dart';
import 'package:bupko_v2/services/epub_downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'services/auth_service.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;
  final String categoryName;

  const BookDetailPage({
    super.key,
    required this.book,
    required this.categoryName,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  double _progress = 0.0;
  bool _downloading = false;
  String? _filePath;
  String? _description;
  bool _loadingDescription = true;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    fetchBookDescription();
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final bookId = '${widget.book.title}_${widget.book.author}';
    String filePath = "${appDocDir.path}/book_$bookId.epub";
    File file = File(filePath);
    if (await file.exists()) {
      setState(() {
        _isDownloaded = true;
        _filePath = filePath;
      });
    }
  }

  Future<void> fetchBookDescription() async {
    final title = Uri.encodeComponent(widget.book.title);
    final url = 'https://www.googleapis.com/books/v1/volumes?q=$title';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['totalItems'] > 0) {
          final volumeInfo = data['items'][0]['volumeInfo'];
          setState(() {
            _description = volumeInfo['description'] ?? 'No description found.';
            _loadingDescription = false;
          });
        } else {
          setState(() {
            _description = 'No description found.';
            _loadingDescription = false;
          });
        }
      } else {
        setState(() {
          _description = 'Failed to fetch description.';
          _loadingDescription = false;
        });
      }
    } catch (e) {
      setState(() {
        _description = 'Failed to fetch description.';
        _loadingDescription = false;
      });
    }
  }

  void startDownload() async {
    if (widget.book.epubHREF == null || widget.book.epubHREF!.isEmpty) return;

    setState(() => _downloading = true);

    EpubDownloader downloader = EpubDownloader();
    _filePath = await downloader.downloadEpub(
      widget.book.epubHREF!,
      (received, total) {
        if (total != -1) {
          setState(() => _progress = received / total);
        }
      },
      {
        'id':
            '${widget.book.title}_${widget.book.author}', // or a unique id if available
        'title': widget.book.title,
        'author': widget.book.author,
        'language': widget.book.language,
        'imageSRC': widget.book.imageSRC,
        'readonlineHREF': widget.book.readonlineHREF,
        'epubHREF': widget.book.epubHREF,
      },
    );

    setState(() {
      _downloading = false;
      if (_filePath != null) {
        _isDownloaded = true;
      }
    });

    if (_filePath != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EpubReaderScreen(epubPath: _filePath!),
        ),
      );
    }
  }

  void _onReadBook() {
    if (_filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EpubReaderScreen(epubPath: _filePath!),
        ),
      );
    }
  }

  Future<bool> _requireAuth() async {
    if (AuthService().currentUser != null) return true;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          onSignUp: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SignUpPage(onSignIn: () => Navigator.pop(context)),
              ),
            );
          },
        ),
      ),
    );
    return result == true && AuthService().currentUser != null;
  }

  void _onPlayBook() async {
    if (await _requireAuth()) {
      startDownload();
    }
  }

  void _onFavorite() async {
    if (await _requireAuth()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book added to favorites!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Detail'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: _onFavorite,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryName,
                          style: TextStyle(
                            color: Colors.lightBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.book.title,
                          style: const TextStyle(
                            color: Color(0xFF1D1D1F),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('By ${widget.book.author}'),
                        const SizedBox(height: 8),
                        const Text('Published August 28th 2012'),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: widget.book.imageSRC,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Reads', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('5.1M'),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(color: Colors.grey),
                  ),
                  Column(
                    children: [
                      Text('Likes', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('37.6K'),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(color: Colors.grey),
                  ),
                  Column(
                    children: [
                      Text('Episodes', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('25'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Text(
              //   widget.book.title,
              //   style: Theme.of(context).textTheme.titleLarge,
              // ),
              // const SizedBox(height: 24),
              Text(
                "About this Ebook",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
              _loadingDescription
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Text(
                      _description ?? '',
                       style: Theme.of(context).textTheme.bodyMedium,
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _downloading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 10),
                  Text("${(_progress * 100).toStringAsFixed(1)}% loaded"),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Read Online'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isDownloaded ? _onReadBook : _onPlayBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isDownloaded ? 'Read' : 'Download'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
