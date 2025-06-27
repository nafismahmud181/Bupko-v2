import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_books_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  Future<QuerySnapshot>? _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesFuture = FirebaseFirestore.instance.collection('categories').get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: FutureBuilder<QuerySnapshot>(
          future: _categoriesFuture,
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
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final categoryData = category.data() as Map<String, dynamic>;
                  final categoryName = category['categoryName'] ?? '';
                  final imageUrl = (categoryData.containsKey('image') && (categoryData['image'] ?? '').toString().isNotEmpty)
                      ? categoryData['image']
                      : 'https://www.keycdn.com/img/support/image-processing-lg.webp';
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
      ),
    );
  }
} 