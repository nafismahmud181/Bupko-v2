import 'package:bupko_v2/auth/login_page.dart';
import 'package:bupko_v2/auth/signup_page.dart';
import 'package:bupko_v2/screens/bottomnav.dart';
import 'package:bupko_v2/services/auth_service.dart';
import 'package:bupko_v2/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await AuthService().signOut();
                if (mounted) {
                  // After logout, just pop the profile page
                  Navigator.of(context).pop();
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () async {
                await Navigator.push<bool>(
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
                // After login, pop the profile page to return to the previous screen
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
    );
  }
} 