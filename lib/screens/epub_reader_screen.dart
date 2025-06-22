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

  @override
  void initState() {
    super.initState();
    _epubController = EpubController(
      document: EpubDocument.openFile(File(widget.epubPath)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Epub Reader")),
      body: EpubView(controller: _epubController),
    );
  }
} 