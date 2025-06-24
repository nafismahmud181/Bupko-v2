import 'dart:io';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';

class EpubReaderScreen extends StatefulWidget {
  final String epubPath;
  const EpubReaderScreen({super.key, required this.epubPath});

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  late EpubController _epubController;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Add GlobalKey to fix Scaffold.of() issue
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeEpub();
  }

  void _initializeEpub() async {
    try {
      _epubController = EpubController(
        document: EpubDocument.openFile(File(widget.epubPath)),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading EPUB: $e';
      });
    }
  }

  @override
  void dispose() {
    _epubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Add the key here
      appBar: AppBar(
        title: const Text("Epub Reader"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              // Use the GlobalKey to open drawer
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
      drawer: _isLoading || _errorMessage != null
          ? null
          : Drawer(
              child: Column(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: Center(
                      child: Text(
                        'Table of Contents',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: EpubViewTableOfContents(
                      controller: _epubController,
                      itemBuilder: (context, index, chapter, itemCount) {
                        return ListTile(
                          title: Text(
                            'Chapter ${index + 1}', // Simple chapter numbering
                            style: const TextStyle(fontSize: 16),
                          ),
                          leading: const Icon(Icons.book_outlined),
                          onTap: () {
                            // Navigate to chapter using scrollTo with index
                            _epubController.scrollTo(index: index);
                            Navigator.of(context).pop(); // Close drawer
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      body: _buildBody(),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading EPUB...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeEpub();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return EpubView(
      controller: _epubController,
      onExternalLinkPressed: (href) {
        // Handle external links
        print('External link pressed: $href');
      },
      onChapterChanged: (chapter) {
        // Update UI when chapter changes
        print('Chapter changed');
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous page button
          IconButton(
            onPressed: () {
              // This is a basic implementation - you might need to implement 
              // more sophisticated navigation based on your needs
              // For now, we'll disable these buttons since the package
              // doesn't provide direct page navigation methods
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Use swipe gestures or tap to navigate'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.keyboard_arrow_left),
            tooltip: 'Previous Page (Use swipe)',
          ),
          
          // Chapter info and reading progress
          Expanded(
            child: EpubViewActualChapter(
              controller: _epubController,
              builder: (chapterValue) => Center(
                child: Text(
                  'Reading...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          
          // Next page button
          IconButton(
            onPressed: () {
              // This is a basic implementation - you might need to implement 
              // more sophisticated navigation based on your needs
              // For now, we'll disable these buttons since the package
              // doesn't provide direct page navigation methods
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Use swipe gestures or tap to navigate'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.keyboard_arrow_right),
            tooltip: 'Next Page (Use swipe)',
          ),
        ],
      ),
    );
  }
}