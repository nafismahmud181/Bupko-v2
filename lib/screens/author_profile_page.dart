import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../book_detail_page.dart';

class AuthorProfilePage extends StatelessWidget {
  final String authorName;
  const AuthorProfilePage({super.key, required this.authorName});

  Future<List<Map<String, dynamic>>> _fetchBooksByAuthor() async {
    final categories = await FirebaseFirestore.instance.collection('categories').get();
    List<Map<String, dynamic>> booksWithCategory = [];
    for (var category in categories.docs) {
      final booksSnapshot = await category.reference.collection('books')
          .where('author', isEqualTo: authorName)
          .get();
      for (var doc in booksSnapshot.docs) {
        final data = doc.data();
        data['categoryName'] = category['categoryName'];
        booksWithCategory.add(data);
      }
    }
    return booksWithCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(authorName)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBooksByAuthor(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No books found for this author.'));
          }
          final books = snapshot.data!;
          return ListView.separated(
            itemCount: books.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final bookMap = books[index];
              final book = Book.fromJson(bookMap);
              final categoryName = bookMap['categoryName'] ?? '';
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
                title: Text(
                  book.title,
                  style: const TextStyle(
                    color: Color(0xFF1D1D1F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(categoryName),
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
          );
        },
      ),
    );
  }
} 