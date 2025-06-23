import 'package:bupko_v2/book_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'category_page.dart';
import 'search_page.dart';
import 'services/auth_service.dart';
import 'screens/library_page.dart';
import 'category_books_page.dart';

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
      final categoryName = categoryDoc['categoryName'] as String;
      final booksSnapshot = await categoryDoc.reference.collection('books').get();
      final books = booksSnapshot.docs.map((doc) => Book.fromJson(doc.data())).toList();
      categories.add(BookCategory(categoryName: categoryName, books: books));
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
        appBar: AppBar(
          title: Text(
            'Hello ${_capitalize(
              AuthService().currentUser?.displayName ??
              AuthService().currentUser?.email?.split('@').first ??
              'Guest'
            )}',
          ),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                ),
                child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Categories'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_books),
                title: const Text('Library'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LibraryPage()),
                  );
                },
              ),
              const Spacer(),
              if (AuthService().currentUser != null)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false,
                      );
                      setState(() {}); // Refresh UI
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Login'),
                  onTap: () async {
                    Navigator.of(context).pop(); // Close drawer
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          onSignUp: () {}, // You can add sign up navigation if needed
                        ),
                      ),
                    );
                    if (result == true && context.mounted) {
                      setState(() {}); // Refresh UI after login
                    }
                  },
                ),
            ],
          ),
        ),
        body: _bookCategories.isEmpty
            ? const Center(child: Text('No books found.'))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            // Get image from Firestore category document
                            final firestoreCategory = FirebaseFirestore.instance.collection('categories').where('categoryName', isEqualTo: category.categoryName);
                            final imageUrl = category.books.isNotEmpty && category.books.first.imageSRC.isNotEmpty
                              ? category.books.first.imageSRC
                              : '';
                            final categoryDoc = FirebaseFirestore.instance.collection('categories').where('categoryName', isEqualTo: category.categoryName);
                            // Use the image from Firestore if available
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
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: _bookCategories.map((category) {
                          final isSelected =
                              category.categoryName == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category.categoryName),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = category.categoryName;
                                });
                              }
                            },
                            backgroundColor: Colors.grey[800],
                            selectedColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                            shape: const StadiumBorder(),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Popular Books',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: popularBooks.length,
                          itemBuilder: (context, index) {
                            final book = popularBooks[index];
                            final categoryName = _selectedCategory;
                            return Row(
                              children: [
                                GestureDetector(
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
                                    width: 130,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: book.imageSRC.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: book.imageSRC,
                                                  height: 190,
                                                  width: 130,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                        height: 190,
                                                        width: 150,
                                                        color: Colors.grey[800],
                                                        child: const Center(
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      ),
                                                  errorWidget: (context, url, error) =>
                                                      Container(
                                                        height: 190,
                                                        width: 150,
                                                        color: Colors.grey[800],
                                                        child: const Icon(Icons.book),
                                                      ),
                                                )
                                              : Container(
                                                  height: 190,
                                                  width: 130,
                                                  color: Colors.grey[800],
                                                  child: const Icon(Icons.book),
                                                ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          book.title.length > 13
                                              ? '${book.title.substring(0, 13)}...'
                                              : book.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          book.author.length > 13
                                              ? '${book.author.substring(0, 13)}...'
                                              : book.author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (index != popularBooks.length - 1)
                                  const SizedBox(width: 16),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
          icon: const Icon(Icons.search),
          label: const Text('Search'),
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
