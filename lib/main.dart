import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Campus Marketplace',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF89986D),
          primary: const Color(0xFF89986D),
          secondary: const Color(0xFF9CAB84),
          surface: const Color(0xFFF6F0D7),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F0D7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF89986D),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF89986D),
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: GoogleFonts.montserratTextTheme(
          ThemeData.light().textTheme,
        ).copyWith(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      routerConfig: AppRouter().router,
    );
  }
}
