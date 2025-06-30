import 'package:bupko_v2/book_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'category_page.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/auth_service.dart';
import 'category_books_page.dart';

import 'models/book.dart';
import 'app_colors.dart';
import 'dart:math';
import 'affiliate_book_card.dart';
import 'models/affiliate_book.dart';

// Data Service for optimized data loading
class BookDataService {
  static BookDataService? _instance;
  static BookDataService get instance => _instance ??= BookDataService._();
  BookDataService._();

  List<BookCategory>? _cachedCategories;
  List<AffiliateBook>? _cachedAffiliateBooks;
  DateTime? _lastFetch;

  // Cache data for 5 minutes
  bool get _shouldRefreshCache {
    return _lastFetch == null || 
           DateTime.now().difference(_lastFetch!).inMinutes > 5;
  }

  Future<List<BookCategory>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && !_shouldRefreshCache && _cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      // Get categories first
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      // Batch all book queries using Future.wait for parallel execution
      final List<Future<BookCategory>> categoryFutures = 
          categoriesSnapshot.docs.map((categoryDoc) async {
        final categoryData = categoryDoc.data();
        final categoryName = categoryData['categoryName'] as String;
        final icon = categoryData['Icon'] as String? ?? 'local_offer';
        final image = categoryData['image'] as String? ?? '';

        // Get books for this category with limit
        final booksSnapshot = await categoryDoc.reference
            .collection('books')
            .limit(30) // Reduced from 100 to 30
            .get();

        var books = booksSnapshot.docs
            .map((doc) => Book.fromJson(doc.data()))
            .toList();

        // More efficient shuffle for smaller lists
        if (books.length > 10) {
          books.shuffle();
          books = books.take(20).toList();
        }

        return BookCategory(
          categoryName: categoryName, 
          icon: icon, 
          books: books,
          imageUrl: image,
          categoryRef: categoryDoc.reference,
        );
      }).toList();

      // Wait for all category queries to complete in parallel
      _cachedCategories = await Future.wait(categoryFutures);
      _lastFetch = DateTime.now();

      return _cachedCategories!;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return _cachedCategories ?? [];
    }
  }

  Future<List<AffiliateBook>> getAffiliateBooks({bool forceRefresh = false}) async {
    if (!forceRefresh && !_shouldRefreshCache && _cachedAffiliateBooks != null) {
      return _cachedAffiliateBooks!;
    }

    try {
      final secondaryDb = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'rokomari-aff',
      );
      
      final snapshot = await secondaryDb
          .collection('books-aff')
          .limit(15) // Limit affiliate books
          .get();
      
      _cachedAffiliateBooks = snapshot.docs
          .map((doc) => AffiliateBook.fromFirestore(doc.id, doc.data()))
          .toList();

      return _cachedAffiliateBooks!;
    } catch (e) {
      debugPrint('Error fetching affiliate books: $e');
      return _cachedAffiliateBooks ?? [];
    }
  }

  void clearCache() {
    _cachedCategories = null;
    _cachedAffiliateBooks = null;
    _lastFetch = null;
  }
}

// Updated BookCategory model
class BookCategory {
  final String categoryName;
  final String icon;
  final List<Book> books;
  final String? imageUrl;
  final DocumentReference? categoryRef;

  BookCategory({
    required this.categoryName,
    required this.icon,
    required this.books,
    this.imageUrl,
    this.categoryRef,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<BookCategory> _bookCategories = [];
  List<AffiliateBook> _affiliateBooks = [];
  String _selectedCategory = '';
  bool _loading = true;
  Book? _bookOfTheDay;
  String? _bookOfTheDayCategory;
  DateTime? _lastBookOfTheDayDate;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    
    try {
      // Load both categories and affiliate books in parallel
      final results = await Future.wait([
        BookDataService.instance.getCategories(),
        BookDataService.instance.getAffiliateBooks(),
      ]);

      if (!mounted) return;

      setState(() {
        _bookCategories = results[0] as List<BookCategory>;
        _affiliateBooks = results[1] as List<AffiliateBook>;
        
        if (_bookCategories.isNotEmpty) {
          _selectedCategory = _bookCategories.first.categoryName;
        }
        _loading = false;
      });

      // Pick book of the day after loading
      _pickBookOfTheDay();
      
      // Pre-cache some critical images
      _precacheImages();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('Error loading data: $e');
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load data. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      final results = await Future.wait([
        BookDataService.instance.getCategories(forceRefresh: true),
        BookDataService.instance.getAffiliateBooks(forceRefresh: true),
      ]);

      if (!mounted) return;

      setState(() {
        _bookCategories = results[0] as List<BookCategory>;
        _affiliateBooks = results[1] as List<AffiliateBook>;
      });

      _pickBookOfTheDay();
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }

  void _precacheImages() {
    // Pre-cache first few book images for better performance
    for (final category in _bookCategories.take(3)) {
      for (final book in category.books.take(3)) {
        if (book.imageSRC.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(book.imageSRC), context);
        }
      }
    }
    
    // Pre-cache affiliate book images
    for (final book in _affiliateBooks.take(5)) {
      if (book.imageUrl.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(book.imageUrl), context);
      }
    }
  }

  void _pickBookOfTheDay() {
    // Only pick a new book if it's a new day or not set
    final now = DateTime.now();
    if (_bookOfTheDay != null && _lastBookOfTheDayDate != null &&
        now.difference(_lastBookOfTheDayDate!).inHours < 24) {
      return;
    }

    if (_bookCategories.isEmpty) return;
    
    // Collect all books with their categories
    final allBooks = <Map<String, dynamic>>[];
    for (final cat in _bookCategories) {
      for (final book in cat.books) {
        allBooks.add({'book': book, 'category': cat.categoryName});
      }
    }
    
    if (allBooks.isEmpty) return;
    
    // Use date-based seed for consistency
    final random = Random(now.year * 1000 + now.month * 100 + now.day);
    final picked = allBooks[random.nextInt(allBooks.length)];
    
    setState(() {
      _bookOfTheDay = picked['book'] as Book;
      _bookOfTheDayCategory = picked['category'] as String;
      _lastBookOfTheDayDate = now;
    });
  }

  Widget _buildAffiliateBooks() {
    if (_affiliateBooks.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No affiliate books available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _affiliateBooks.length,
        itemBuilder: (context, index) {
          final book = _affiliateBooks[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: AffiliateBookCard(book: book),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _bookCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _bookCategories[index];
          final imageUrl = _getCategoryImageUrl(category);

          return GestureDetector(
            onTap: () {
              if (category.categoryRef != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryBooksPage(
                      categoryRef: category.categoryRef!,
                      categoryName: category.categoryName,
                    ),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 160,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 160,
                      height: 100,
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 160,
                      height: 100,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.category, 
                        color: Colors.white, 
                        size: 40,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 160,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Text(
                    category.categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getCategoryImageUrl(BookCategory category) {
    // Priority: category.imageUrl > first book image > default
    if (category.imageUrl?.isNotEmpty == true) {
      return category.imageUrl!;
    }
    
    if (category.books.isNotEmpty && category.books.first.imageSRC.isNotEmpty) {
      return category.books.first.imageSRC;
    }
    
    return 'https://www.keycdn.com/img/support/image-processing-lg.webp';
  }

  @override
  Widget build(BuildContext context) {
    List<Book> popularBooks = [];
    if (_bookCategories.isNotEmpty) {
      final category = _bookCategories.firstWhere(
        (cat) => cat.categoryName == _selectedCategory,
        orElse: () => _bookCategories.first,
      );
      popularBooks = category.books;
    }

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your books...'),
            ],
          ),
        ),
      );
    }

    final user = AuthService().currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        final bool shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Exit App'),
                  content: const Text('Are you sure you want to leave?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                );
              },
            ) ?? false;
            
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: _bookCategories.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No books found.'),
                    SizedBox(height: 8),
                    Text('Pull down to refresh', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Fixed header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: _HomeHeader(name: name),
                  ),
                  // Main scrollable content
                  Padding(
                    padding: const EdgeInsets.only(top: 130),
                    child: RefreshIndicator(
                      onRefresh: _refreshData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Book of the Day
                            if (_bookOfTheDay != null && _bookOfTheDayCategory != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, 
                                  vertical: 12.0,
                                ),
                                child: _BookOfTheDayCard(
                                  book: _bookOfTheDay!,
                                  category: _bookOfTheDayCategory!,
                                ),
                              ),
                            
                            // Affiliate Books Section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, 
                                vertical: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Affiliate Books',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAffiliateBooks(),
                                ],
                              ),
                            ),
                            
                            // Category Selection and Books
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category chips
                                  SizedBox(
                                    height: 50,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _bookCategories.length,
                                      separatorBuilder: (context, index) => 
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final category = _bookCategories[index];
                                        final isSelected = 
                                            category.categoryName == _selectedCategory;
                                        return _CategoryChip(
                                          label: category.categoryName,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              _selectedCategory = category.categoryName;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Popular books horizontal list
                                  SizedBox(
                                    height: 300,
                                    child: popularBooks.isEmpty
                                        ? const Center(
                                            child: Text('No books in this category'),
                                          )
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: popularBooks.length,
                                            itemBuilder: (context, index) {
                                              final book = popularBooks[index];
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 16.0),
                                                child: _BookCard(
                                                  book: book, 
                                                  categoryName: _selectedCategory,
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Explore by Genre section
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Explore by Genre',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const CategoryPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Category grid
                                  _buildCategoryGrid(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? const Color.fromARGB(255, 51, 75, 235) 
                  : AppColors.primaryText,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final String categoryName;

  const _BookCard({required this.book, required this.categoryName});

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
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: book.imageSRC,
                    height: 220,
                    width: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 220,
                      width: 150,
                      color: Colors.grey[800],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 220,
                      width: 150,
                      color: Colors.grey[800],
                      child: const Icon(Icons.book, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '4.5/5',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String? name;
  const _HomeHeader({this.name});

  @override
  Widget build(BuildContext context) {
    String? displayName = name != null && name!.isNotEmpty
        ? name![0].toUpperCase() + name!.substring(1)
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                displayName != null ? 'Hello $displayName,' : 'Hello!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'What book would you like to read?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 66),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined, 
                size: 28, 
                color: Color(0xFF1D1D1F),
              ),
              onPressed: () {},
            ),
            Positioned(
              right: 6,
              top: 20,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BookOfTheDayCard extends StatelessWidget {
  final Book book;
  final String category;
  const _BookOfTheDayCard({required this.book, required this.category});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailPage(
                book: book, 
                categoryName: category,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 120,
                  child: book.imageSRC.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.imageSRC,
                          width: 90,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 90,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 90,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, size: 40),
                          ),
                        )
                      : Container(
                          width: 90,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.book, size: 40),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Book of the Day',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.author,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}