class AffiliateBook {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String affLink;
  final String actualPrice;
  final String discPrice;

  AffiliateBook({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.affLink,
    required this.actualPrice,
    required this.discPrice,
  });

  factory AffiliateBook.fromFirestore(String id, Map<String, dynamic> data) {
    return AffiliateBook(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      imageUrl: data['image-url'] ?? '',
      affLink: data['aff-link'] ?? '',
      actualPrice: data['actual-price'] ?? '',
      discPrice: data['disc-price'] ?? '',
    );
  }
} 