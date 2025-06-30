import 'package:flutter/material.dart';

class UploadResearchBookPage extends StatefulWidget {
  const UploadResearchBookPage({Key? key}) : super(key: key);

  @override
  State<UploadResearchBookPage> createState() => _UploadResearchBookPageState();
}

class _UploadResearchBookPageState extends State<UploadResearchBookPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Awesome Thesis Report'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Outline'),
            Tab(text: 'Figures & Tables'),
            Tab(text: 'References'),
            Tab(text: 'Export'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Outline tab (to be filled with template in next step)
          Center(child: Text('Outline')),
          Center(child: Text('Figures & Tables')),
          Center(child: Text('References')),
          Center(child: Text('Export')),
        ],
      ),
    );
  }
} 