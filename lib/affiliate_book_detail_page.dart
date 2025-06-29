import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/affiliate_book.dart';

class AffiliateBookDetailPage extends StatefulWidget {
  final AffiliateBook book;

  const AffiliateBookDetailPage({
    super.key,
    required this.book,
  });

  @override
  State<AffiliateBookDetailPage> createState() => _AffiliateBookDetailPageState();
}

class _AffiliateBookDetailPageState extends State<AffiliateBookDetailPage> {
  bool _isLoading = false;

  Future<void> _launchAffiliateLink() async {
    if (widget.book.affLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase link not available')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Attempting to launch URL: ${widget.book.affLink}');
      
      // Clean and validate the URL
      String urlString = widget.book.affLink.trim();
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      
      final Uri url = Uri.parse(urlString);
      print('Parsed URL: $url');
      
      // Try to launch directly without checking canLaunchUrl first
      bool launched = false;
      
      try {
        print('Trying external application...');
        launched = await launchUrl(
          url, 
          mode: LaunchMode.externalApplication,
        );
        print('External application result: $launched');
      } catch (e) {
        print('External application failed: $e');
      }
      
      if (!launched) {
        try {
          print('Trying in-app browser...');
          launched = await launchUrl(
            url,
            mode: LaunchMode.inAppWebView,
          );
          print('In-app browser result: $launched');
        } catch (e) {
          print('In-app browser failed: $e');
        }
      }
      
      if (!launched) {
        try {
          print('Trying platform default...');
          launched = await launchUrl(url);
          print('Platform default result: $launched');
        } catch (e) {
          print('Platform default failed: $e');
        }
      }
      
      print('Final launch result: $launched');
      
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open purchase link. Please try again.')),
        );
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening purchase link: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Affiliate Book',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.book.title,
                          style: const TextStyle(
                            color: Color(0xFF1D1D1F),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By ${widget.book.author}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (widget.book.discPrice.isNotEmpty)
                              Text(
                                '৳${widget.book.discPrice}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            if (widget.book.actualPrice.isNotEmpty && widget.book.actualPrice != widget.book.discPrice)
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Text(
                                  '৳${widget.book.actualPrice}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (widget.book.discPrice.isNotEmpty && widget.book.actualPrice.isNotEmpty && widget.book.actualPrice != widget.book.discPrice)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${((double.tryParse(widget.book.actualPrice) ?? 0) - (double.tryParse(widget.book.discPrice) ?? 0)).toStringAsFixed(0)}৳ OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: CachedNetworkImage(
                        imageUrl: widget.book.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.book, size: 60),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                "About this Book",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This is an affiliate book available for purchase. Click the button below to buy this book from our partner store.",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Features:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "• Physical book delivery\n• Secure payment\n• Fast shipping\n• Money-back guarantee",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _launchAffiliateLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
} 