import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'book_detail_page.dart';
import 'models/book.dart';

class CategoryBooksPage extends StatelessWidget {
  final DocumentReference categoryRef;
  final String categoryName;
  const CategoryBooksPage({super.key, required this.categoryRef, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: FutureBuilder<QuerySnapshot>(
        future: categoryRef.collection('books').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No books found in this category.'));
          }
          final books = snapshot.data!.docs;
          return ListView.separated(
            itemCount: books.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final bookMap = books[index].data() as Map<String, dynamic>;
              final book = Book.fromJson(bookMap);
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
          );
        },
      ),
    );
  }
} 