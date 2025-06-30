import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'book_detail_page.dart';
import 'models/book.dart';

class CategoryBooksPage extends StatefulWidget {
  final DocumentReference categoryRef;
  final String categoryName;
  const CategoryBooksPage({super.key, required this.categoryRef, required this.categoryName});

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  List<Book> _books = [];
  bool _loading = true;
  int _displayCount = 10;
  final ScrollController _scrollController = ScrollController();
  bool _showSeeMore = false;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 100.0; // px from bottom to show button
    final shouldShow = (_displayCount < _books.length) && (maxScroll - currentScroll <= threshold);
    if (_showSeeMore != shouldShow) {
      setState(() {
        _showSeeMore = shouldShow;
      });
    }
  }

  Future<void> _fetchBooks() async {
    setState(() => _loading = true);
    final snapshot = await widget.categoryRef.collection('books').get();
    final books = snapshot.docs.map((doc) => Book.fromJson(doc.data())).toList();
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  void _loadMore() {
    setState(() {
      _displayCount = (_displayCount + 10).clamp(0, _books.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(child: Text('No books found in this category.'))
              : Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.6,
                            ),
                            itemCount: _displayCount.clamp(0, _books.length),
                            itemBuilder: (context, index) {
                              final book = _books[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookDetailPage(
                                        book: book,
                                        categoryName: widget.categoryName,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: book.imageSRC,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: double.infinity,
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Center(child: CircularProgressIndicator()),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: double.infinity,
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.book, size: 40),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      book.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      book.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_showSeeMore)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 24,
                        child: Center(
                          child: FloatingActionButton.extended(
                            onPressed: _loadMore,
                            label: const Text('See More'),
                            icon: const Icon(Icons.expand_more),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
} 