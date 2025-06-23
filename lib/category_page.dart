import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_books_page.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('categories').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          final categories = snapshot.data!.docs;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryName = category['categoryName'] ?? '';
                final imageUrl = category['image'] ?? '';
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryBooksPage(
                          categoryRef: category.reference,
                          categoryName: categoryName,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.broken_image, size: 60, color: Colors.white),
                                      ),
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.category, size: 60, color: Colors.white),
                                ),
                        ),
                        // Overlay for category name
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            color: Colors.black.withValues(alpha: 0.55),
                            child: Center(
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black54,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 