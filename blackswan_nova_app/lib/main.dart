import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const BlackswanNovaApp());
}

class BlackswanNovaApp extends StatelessWidget {
  const BlackswanNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLACKSWAN NOVA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        primaryColor: const Color(0xFF00F0FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFF7B61FF),
          surface: Color(0xFF111827),
          error: Color(0xFFFF4757),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0A0E17),
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00F0FF),
            letterSpacing: 2,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
