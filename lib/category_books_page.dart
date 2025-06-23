import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
              final book = books[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: book['image_src'] != null && (book['image_src'] as String).isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book['image_src'],
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
                title: Text(book['title'] ?? ''),
                subtitle: Text(book['author'] ?? ''),
                onTap: () {
                  // TODO: Navigate to book details
                },
              );
            },
          );
        },
      ),
    );
  }
} 