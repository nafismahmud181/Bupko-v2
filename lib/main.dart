import 'package:bupko_v2/category_page.dart';
import 'package:bupko_v2/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'home_page.dart';
// import 'package:bupko_v2/models/bottom_nav.dart';
import 'package:bupko_v2/screens/bottomnav.dart';
import 'package:bupko_v2/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, themeProvider, Widget? child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Ebook Library',
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.white,
              dividerColor: AppColors.placeholder,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.primaryText),
                titleTextStyle: TextStyle(color: AppColors.primaryText, fontSize: 20, fontWeight: FontWeight.bold)
              ),
              fontFamily: GoogleFonts.rethinkSans().fontFamily,
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: AppColors.primaryText),
                bodyMedium: TextStyle(color: AppColors.secondaryText),
                titleLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
              ),
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                background: AppColors.background,
                surface: AppColors.white,
                onPrimary: AppColors.white,
                onSurface: AppColors.primaryText,
                secondary: AppColors.progress,
                error: AppColors.notification,
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.primaryButton),
                  shape: const StadiumBorder(),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                ),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.placeholder),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.placeholder),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                labelStyle: TextStyle(color: AppColors.secondaryText),
                hintStyle: TextStyle(color: AppColors.placeholder),
                fillColor: AppColors.white,
                filled: true,
              ),
              progressIndicatorTheme: const ProgressIndicatorThemeData(
                color: AppColors.progress,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: const Color(0xFF121212),
              scaffoldBackgroundColor: AppColors.darkBackground,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.darkBackground,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              fontFamily: GoogleFonts.rethinkSans().fontFamily,
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: AppColors.darkBackground,
              ),
            ),
            themeMode: themeProvider.darkTheme ? ThemeMode.dark : ThemeMode.light,
            home: const BottomNav(),
          );
        },
      ),
    );
  }
}
