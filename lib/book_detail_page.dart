import 'package:bupko_v2/models/book.dart';
import 'package:bupko_v2/screens/epub_reader_screen.dart';
import 'package:bupko_v2/services/epub_downloader.dart';
import 'package:flutter/material.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  double _progress = 0.0;
  bool _downloading = false;
  String? _filePath;

  void startDownload() async {
    if (widget.book.epubHREF == null || widget.book.epubHREF!.isEmpty) return;

    setState(() => _downloading = true);

    EpubDownloader downloader = EpubDownloader();
    _filePath =
        await downloader.downloadEpub(widget.book.epubHREF!, (received, total) {
      if (total != -1) {
        setState(() => _progress = received / total);
      }
    });

    setState(() => _downloading = false);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Detail'),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.favorite_border),
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
                        const Text(
                          '#3 On Trending',
                          style: TextStyle(
                            color: Colors.lightBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.book.title,
                          style: const TextStyle(
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
                      child: Image.network(
                        widget.book.imageSRC,
                        fit: BoxFit.cover,
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
                      Text(
                        'Reads',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text('5.1M'),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      color: Colors.grey,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Likes',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text('37.6K'),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      color: Colors.grey,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Episodes',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text('25'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'The Song Of Achilles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Nafis',
                style: TextStyle(color: Colors.grey),
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
                        side: const BorderSide(color: Colors.white),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Read Book'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: startDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Play Book'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 