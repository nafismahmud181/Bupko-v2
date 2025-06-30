import 'package:bupko_v2/home_page.dart';
import 'package:bupko_v2/profile_page.dart';
import 'package:bupko_v2/screens/library_page.dart';
// import 'package:bupko_v2/search_page.dart';
import 'package:flutter/material.dart';
import 'package:bupko_v2/category_page.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CategoryPage(),
    // const SearchPage(),
    const LibraryPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        } else {
          final shouldExit = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Exit App'),
                    content: const Text('Are you sure you want to leave?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              ) ??
              false;
          return shouldExit;
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(.1),
              )
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.category_outlined),
                    activeIcon: Icon(Icons.category),
                    label: 'Category',
                  ),
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.search_outlined),
                  //   activeIcon: Icon(Icons.search),
                  //   label: 'Search',
                  // ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bookmark_border),
                    activeIcon: Icon(Icons.bookmark),
                    label: 'Library',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.black,
                unselectedItemColor: Colors.grey,
                onTap: _onItemTapped,
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                showUnselectedLabels: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 