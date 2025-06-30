import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../book_detail_page.dart';
import '../services/auth_service.dart';

class AuthorProfilePage extends StatefulWidget {
  final String authorName;
  const AuthorProfilePage({super.key, required this.authorName});

  @override
  State<AuthorProfilePage> createState() => _AuthorProfilePageState();
}

class _AuthorProfilePageState extends State<AuthorProfilePage> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<Map<String, dynamic>>> _fetchBooksByAuthor() async {
    final categories = await FirebaseFirestore.instance.collection('categories').get();
    List<Map<String, dynamic>> booksWithCategory = [];
    for (var category in categories.docs) {
      final booksSnapshot = await category.reference.collection('books')
          .where('author', isEqualTo: widget.authorName)
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
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // Custom header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Text(
                          'Author Details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/32.jpg'), // Placeholder
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'United States, America', // Placeholder
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    _FollowSection(authorName: widget.authorName, booksCount: books.length),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.55,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final bookMap = books[index];
                          final book = Book.fromJson(bookMap);
                          final categoryName = bookMap['categoryName'] ?? '';
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: book.imageSRC,
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: double.infinity,
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: double.infinity,
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.book, size: 40),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  categoryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _FollowSection extends StatefulWidget {
  final String authorName;
  final int booksCount;
  const _FollowSection({required this.authorName, required this.booksCount});

  @override
  State<_FollowSection> createState() => _FollowSectionState();
}

class _FollowSectionState extends State<_FollowSection> {
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkFollowing();
  }

  Future<void> _checkFollowing() async {
    final isFollowing = await AuthService().isFollowingAuthor(widget.authorName);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to follow authors.')));
      return;
    }
    if (_isFollowing) {
      await AuthService().unfollowAuthor(widget.authorName);
      if (mounted) {
        setState(() => _isFollowing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfollowed author')));
      }
    } else {
      await AuthService().followAuthor(widget.authorName);
      if (mounted) {
        setState(() => _isFollowing = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Followed author')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 38,
          child: ElevatedButton(
            onPressed: _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? Colors.grey : const Color(0xFF4AD0A0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              _isFollowing ? 'FOLLOWING' : 'FOLLOW',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatCard(icon: Icons.menu_book, label: 'Books, Podcast', value: '${widget.booksCount}+',),
            _StatCard(icon: Icons.star, label: 'Rating & reviews', value: '4.5k+',),
            StreamBuilder<int>(
              stream: AuthService().getFollowersCountStream(widget.authorName),
              builder: (context, snap) {
                final followers = snap.data ?? 0;
                return _StatCard(icon: Icons.people, label: 'Followers', value: '$followers+',);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[700], size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
} 