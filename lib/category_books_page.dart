import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'book_detail_page.dart';
import 'models/book.dart';

class CategoryBooksPage extends StatefulWidget {
  final DocumentReference categoryRef;
  final String categoryName;
  
  const CategoryBooksPage({
    super.key, 
    required this.categoryRef, 
    required this.categoryName,
  });

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  List<Book> _books = [];
  bool _loading = true;
  int _displayCount = 10;
  final ScrollController _scrollController = ScrollController();
  bool _showSeeMore = false;

  // Constants for better maintainability
  static const int _itemsPerLoad = 10;
  static const double _scrollThreshold = 100.0;
  static const double _imageHeight = 220.0;
  static const double _childAspectRatio = 0.5;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final position = _scrollController.position;
    final shouldShow = (_displayCount < _books.length) && 
                     (position.maxScrollExtent - position.pixels <= _scrollThreshold);
    
    if (_showSeeMore != shouldShow) {
      setState(() => _showSeeMore = shouldShow);
    }
  }

  Future<void> _fetchBooks() async {
    try {
      setState(() => _loading = true);
      
      final snapshot = await widget.categoryRef
          .collection('books')
          .get(const GetOptions(source: Source.cache)); // Try cache first
      
      List<Book> books;
      
      if (snapshot.docs.isEmpty) {
        // If cache is empty, fetch from server
        final serverSnapshot = await widget.categoryRef
            .collection('books')
            .get(const GetOptions(source: Source.server));
        books = serverSnapshot.docs
            .map((doc) => Book.fromJson(doc.data()))
            .toList();
      } else {
        books = snapshot.docs
            .map((doc) => Book.fromJson(doc.data()))
            .toList();
      }
      
      if (mounted) {
        setState(() {
          _books = books;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading books: $e')),
        );
      }
    }
  }

  void _loadMore() {
    setState(() {
      _displayCount = (_displayCount + _itemsPerLoad).clamp(0, _books.length);
    });
  }

  void _navigateToBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          book: book,
          categoryName: widget.categoryName,
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToBookDetail(book),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: book.imageSRC,
                  width: double.infinity,
                  height: _imageHeight,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: double.infinity,
                    height: _imageHeight,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: _imageHeight,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No books found in this category.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchBooks,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: _childAspectRatio, // Taller cards
      ),
      itemCount: _displayCount.clamp(0, _books.length),
      itemBuilder: (context, index) => _buildBookCard(_books[index]),
    );
  }

  Widget _buildSeeMoreButton() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Center(
        child: FloatingActionButton.extended(
          onPressed: _loadMore,
          label: Text(
            'See More (${_books.length - _displayCount} left)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.expand_more),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_loading && _books.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_books.length} books',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBooks,
        child: _loading
            ? _buildLoadingState()
            : _books.isEmpty
                ? _buildEmptyState()
                : Stack(
                    children: [
                      _buildBooksGrid(),
                      if (_showSeeMore) _buildSeeMoreButton(),
                    ],
                  ),
      ),
    );
  }
}