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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: user != null
                            ? Text(
                                user.displayName?.isNotEmpty == true
                                    ? user.displayName![0].toUpperCase()
                                    : user.email![0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName!
                            : user?.email ?? 'Guest User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (user != null && user.displayName?.isNotEmpty == true)
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reading Preferences Section
                  _buildSectionHeader('Reading Preferences'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle: 'Easier on the eyes',
                      value: themeProvider.darkTheme,
                      onChanged: (value) {
                        themeProvider.setDarkTheme(value);
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Content Section
                  _buildSectionHeader('Content'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: Icons.edit_note,
                      title: 'Write Thesis/Report',
                      subtitle: 'Create your research document',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UploadResearchBookPage(),
                          ),
                        );
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.library_books,
                      title: 'My Library',
                      subtitle: 'View your collection',
                      onTap: () {
                        // Navigate to library
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.bookmark,
                      title: 'Bookmarks',
                      subtitle: 'Your saved pages',
                      onTap: () {
                        // Navigate to bookmarks
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Account Section
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    if (user != null)
                      _buildActionTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        onTap: () async {
                          await _showLogoutDialog();
                        },
                        isDestructive: true,
                      )
                    else
                      _buildActionTile(
                        icon: Icons.login,
                        title: 'Login',
                        subtitle: 'Sign in to sync your data',
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
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // About Section
                  _buildSectionHeader('About'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildActionTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help with the app',
                      onTap: () {
                        // Navigate to help
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App version and info',
                      onTap: () {
                        // Show about dialog
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Theme.of(context).primaryColor;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
      onTap: onTap,
    );
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BottomNav()),
          (route) => false,
        );
      }
    }
  }
}