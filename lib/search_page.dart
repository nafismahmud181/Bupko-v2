import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models/book.dart';
import 'book_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  List<QueryDocumentSnapshot> _results = [];
  bool _loading = false;
  final TextEditingController _controller = TextEditingController();

  void _onSearchChanged(String value) async {
    setState(() {
      _query = value;
      _loading = true;
    });
    if (value.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    try {
      final categories = await FirebaseFirestore.instance.collection('categories').get();
      // Fetch all books in parallel
      final futures = categories.docs.map((category) {
        return category.reference.collection('books').get();
      }).toList();
      final booksSnapshots = await Future.wait(futures);
      List<QueryDocumentSnapshot> books = [];
      for (int i = 0; i < booksSnapshots.length; i++) {
        books.addAll(booksSnapshots[i].docs);
      }
      final filtered = books.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] ?? '').toString().toLowerCase().trim();
        final query = value.toLowerCase().trim();
        return title.contains(query);
      }).toList();
      setState(() {
        _results = filtered;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search by book title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          if (!_loading && _results.isEmpty && _query.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No books found.'),
            ),
          if (_results.isNotEmpty)
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final bookMap = _results[index].data() as Map<String, dynamic>;
                  final book = Book.fromJson(bookMap);
                  final categoryName = _results[index].reference.parent.parent?.id ?? '';
                  return ListTile(
                    leading: book.imageSRC.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: book.imageSRC,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 50,
                              height: 70,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.book),
                          )
                        : const Icon(Icons.book, size: 50),
                    title: Text(book.title),
                    subtitle: Text(book.author),
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 