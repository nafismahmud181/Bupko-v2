class Book {
  final String title;
  final String author;
  final String language;
  final String imageSRC;
  final String readonlineHREF;
  final String? epubHREF;
  final String? cbzHREF;

  Book({
    required this.title,
    required this.author,
    required this.language,
    required this.imageSRC,
    required this.readonlineHREF,
    this.epubHREF,
    this.cbzHREF,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'],
      author: json['author'],
      language: json['language'],
      imageSRC: json['imageSRC'],
      readonlineHREF: json['readonlineHREF'],
      epubHREF: json['epubHREF'],
      cbzHREF: json['cbzHREF'],
    );
  }
}

class BookCategory {
  final String categoryName;
  final List<Book> books;

  BookCategory({required this.categoryName, required this.books});

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    var bookList = json['books'] as List;
    List<Book> books = bookList.map((i) => Book.fromJson(i)).toList();
    return BookCategory(
      categoryName: json['categoryName'],
      books: books,
    );
  }
} 