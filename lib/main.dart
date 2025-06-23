import 'package:bupko_v2/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/splash_screen.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ebook Library',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF121212),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
        ),
        fontFamily: 'Poppins',
      ),
      home: const HomePage(),
    );
  }
}

class _AuthRoot extends StatefulWidget {
  const _AuthRoot({super.key});
  @override
  State<_AuthRoot> createState() => _AuthRootState();
}

class _AuthRootState extends State<_AuthRoot> {
  bool _showSplash = true;
  bool _showLogin = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();
    if (_showLogin) {
      return LoginPage(onSignUp: () => setState(() => _showLogin = false));
    } else {
      return SignUpPage(onSignIn: () => setState(() => _showLogin = true));
    }
  }
}
