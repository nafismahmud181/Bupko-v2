// bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:bupko_v2/search_page.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  const MainScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
        },
        tooltip: 'Search',
        child: const Icon(Icons.search, color: Colors.black),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.home, color: Colors.amber),
                  Text('Home', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 48), // Space for FAB
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/catagories');
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.settings, color: Colors.black45),
                  Text('Categories', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
