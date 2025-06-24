import 'package:bupko_v2/book_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'category_page.dart';

import 'services/auth_service.dart';
import 'screens/library_page.dart';
import 'category_books_page.dart';
import 'profile_page.dart';

import 'models/book.dart';
import 'auth/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<BookCategory> _bookCategories = [];
  String _selectedCategory = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBooksFromFirestore();
  }

  Future<void> _fetchBooksFromFirestore() async {
    setState(() => _loading = true);
    final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();
    List<BookCategory> categories = [];
    for (var categoryDoc in categoriesSnapshot.docs) {
      final categoryData = categoryDoc.data();
      final categoryName = categoryData['categoryName'] as String;
      final icon = categoryData['Icon'] as String? ?? 'local_offer';
      final booksSnapshot = await categoryDoc.reference.collection('books').get();
      final books = booksSnapshot.docs.map((doc) => Book.fromJson(doc.data())).toList();
      categories.add(BookCategory(categoryName: categoryName, icon: icon, books: books));
    }
    if (!mounted) return;
    setState(() {
      _bookCategories = categories;
      if (_bookCategories.isNotEmpty) {
        _selectedCategory = _bookCategories.first.categoryName;
      }
      _loading = false;
    });
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = AuthService().currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first;
    final greeting = name != null ? 'Hello, ${_capitalize(name)}!' : 'Hello!';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
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
            ) ??
            false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: Text(
        //     'Hello ${_capitalize(
        //       AuthService().currentUser?.displayName ??
        //       AuthService().currentUser?.email?.split('@').first ??
        //       'Guest'
        //     )}',
        //   ),
        //   centerTitle: true,
        //   actions: [
        //     Padding(
        //       padding: const EdgeInsets.only(right: 16.0),
        //       child: GestureDetector(
        //         onTap: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(builder: (context) => const ProfilePage()),
        //           );
        //         },
        //         child: const CircleAvatar(
        //           backgroundImage: NetworkImage(
        //             'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        // drawer: Drawer(
        //   child: Column(
        //     children: [
        //       const DrawerHeader(
        //         decoration: BoxDecoration(
        //           color: Colors.deepPurple,
        //         ),
        //         child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
        //       ),
        //       ListTile(
        //         leading: const Icon(Icons.category),
        //         title: const Text('Categories'),
        //         onTap: () {
        //           Navigator.pop(context);
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(builder: (context) => const CategoryPage()),
        //           );
        //         },
        //       ),
        //       ListTile(
        //         leading: const Icon(Icons.library_books),
        //         title: const Text('Library'),
        //         onTap: () {
        //           Navigator.pop(context);
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(builder: (context) => const LibraryPage()),
        //           );
        //         },
        //       ),
        //       ListTile(
        //         leading: const Icon(Icons.person),
        //         title: const Text('Profile'),
        //         onTap: () {
        //           Navigator.pop(context);
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(builder: (context) => const ProfilePage()),
        //           );
        //         },
        //       ),
              
        //     ],
        //   ),
        // ),
        body: _bookCategories.isEmpty
            ? const Center(child: Text('No books found.'))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF233974),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: -20,
                              top: 40,
                              child: Icon(Icons.book, color: Colors.white.withOpacity(0.1), size: 50),
                            ),
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Icon(Icons.book, color: Colors.white.withOpacity(0.1), size: 80),
                            ),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Which book suits your current mood?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 50,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _bookCategories.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final category = _bookCategories[index];
                                final isSelected = category.categoryName == _selectedCategory;
                                return _CategoryChip(
                                  label: category.categoryName,
                                  iconName: category.icon,
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
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: popularBooks.length,
                              itemBuilder: (context, index) {
                                final book = popularBooks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: _BookCard(book: book, categoryName: _selectedCategory),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                    MaterialPageRoute(builder: (context) => const CategoryPage()),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _bookCategories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final category = _bookCategories[index];
                                final firestoreCategory = FirebaseFirestore.instance.collection('categories').where('categoryName', isEqualTo: category.categoryName);
                                final imageUrl = category.books.isNotEmpty && category.books.first.imageSRC.isNotEmpty
                                  ? category.books.first.imageSRC
                                  : '';
                                final categoryDoc = FirebaseFirestore.instance.collection('categories').where('categoryName', isEqualTo: category.categoryName);
                                return FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance.collection('categories').where('categoryName', isEqualTo: category.categoryName).get(),
                                  builder: (context, snapshot) {
                                    String? firestoreImageUrl;
                                    DocumentReference? categoryRef;
                                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                      firestoreImageUrl = snapshot.data!.docs.first['image'] ?? '';
                                      categoryRef = snapshot.data!.docs.first.reference;
                                    }
                                    return GestureDetector(
                                      onTap: () {
                                        if (categoryRef != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CategoryBooksPage(
                                                categoryRef: categoryRef!,
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
                                            child: firestoreImageUrl != null && firestoreImageUrl.isNotEmpty
                                                ? Image.network(
                                                    firestoreImageUrl,
                                                    width: 160,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    width: 160,
                                                    height: 100,
                                                    color: Colors.grey[800],
                                                    child: const Icon(Icons.category, color: Colors.white, size: 40),
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
                                );
                              },
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String iconName;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.iconName,
    required this.isSelected,
    required this.onTap,
  });

  static const Map<String, IconData> _iconMap = {
    'auto_awesome': Icons.auto_awesome,
    'favorite': Icons.favorite,
    'theater_comedy': Icons.theater_comedy,
    'local_offer': Icons.local_offer,
    'museum': Icons.museum,
    'architecture': Icons.architecture,
    'palette': Icons.palette,
    'history_edu': Icons.history_edu,
    // Add other icon mappings here
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF233974) : theme.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: isSelected ? null : Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              _iconMap[iconName] ?? Icons.local_offer,
              size: 20,
              color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.5/5', // This is a placeholder
                          style: const TextStyle(
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
