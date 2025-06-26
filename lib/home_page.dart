import 'package:bupko_v2/book_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'category_page.dart';

import 'services/auth_service.dart';
import 'category_books_page.dart';

import 'models/book.dart';
import 'app_colors.dart';

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
            : RefreshIndicator(
                onRefresh: _fetchBooksFromFirestore,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: _HomeHeader(name: name),
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
    final theme = Theme.of(context);
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
              color: isSelected ? const Color.fromARGB(255, 51, 75, 235) : AppColors.primaryText,
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
              SizedBox(height: 20),
              Text(
                displayName != null ? 'Hello $displayName,' : 'Hello!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F), // AppColors.primaryText
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'What book would you like to read?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500], // AppColors.secondaryText
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 28, color: Color(0xFF1D1D1F)),
              onPressed: () {},
            ),
            Positioned(
              right: 6,
              top: 6,
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
