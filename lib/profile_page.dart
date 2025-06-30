// ignore: file_names
import 'package:bupko_v2/auth/login_page.dart';
import 'package:bupko_v2/auth/signup_page.dart';
import 'package:bupko_v2/screens/bottomnav.dart';
import 'package:bupko_v2/services/auth_service.dart';
import 'package:bupko_v2/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../upload_research_book.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.darkTheme,
              onChanged: (value) {
                themeProvider.setDarkTheme(value);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Write Thesis/Report'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadResearchBookPage(),
                ),
              );
            },
          ),
          const Divider(),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await AuthService().signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const BottomNav()),
                    (route) => false,
                  );
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(
                      onSignUp: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpPage(
                              onSignIn: () => Navigator.of(context).pop(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const BottomNav()),
                    (route) => false,
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
