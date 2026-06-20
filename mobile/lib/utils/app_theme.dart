import 'package:flutter/material.dart';

class AppTheme {
  static const Color vert = Color(0xFF1D9E75);
  static const Color vertFonce = Color(0xFF0F6E56);
  static const Color vertClair = Color(0xFFE1F5EE);
  static const Color vertTresClair = Color(0xFFF0FAF6);

  static const Color orange = Color(0xFFEF9F27);
  static const Color orangeFonce = Color(0xFFBA7517);
  static const Color orangeClair = Color(0xFFFAEEDA);

  static const Color rouge = Color(0xFFE24B4A);
  static const Color rougeClair = Color(0xFFFCEBEB);

  static const Color gris = Color(0xFF888780);
  static const Color grisClair = Color(0xFFF1EFE8);
  static const Color grisTexte = Color(0xFF5F5E5A);

  static const Color blanc = Color(0xFFFFFFFF);
  static const Color fond = Color(0xFFF5F5F5);
  static const Color texte = Color(0xFF2C2C2A);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSeed(
          seedColor: vert,
          primary: vert,
          secondary: orange,
          surface: blanc,
          error: rouge,
        ),
        scaffoldBackgroundColor: fond,
        appBarTheme: const AppBarTheme(
          backgroundColor: vert,
          foregroundColor: blanc,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: blanc,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: vert,
            foregroundColor: blanc,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: vert,
            side: const BorderSide(color: vert, width: 1.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: blanc,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD3D1C7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD3D1C7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: vert, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: rouge),
          ),
          labelStyle: const TextStyle(color: grisTexte, fontFamily: 'Nunito'),
          hintStyle: const TextStyle(color: gris, fontFamily: 'Nunito'),
        ),
        cardTheme: CardThemeData(
          color: blanc,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8E8E5), width: 0.5),
          ),
          margin: const EdgeInsets.only(bottom: 12),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: blanc,
          selectedItemColor: vert,
          unselectedItemColor: gris,
          selectedLabelStyle: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontFamily: 'Nunito', fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: texte, fontFamily: 'Nunito'),
          displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: texte, fontFamily: 'Nunito'),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: texte, fontFamily: 'Nunito'),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: texte, fontFamily: 'Nunito'),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: texte, fontFamily: 'Nunito'),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: texte, fontFamily: 'Nunito'),
          bodyLarge: TextStyle(fontSize: 15, color: texte, fontFamily: 'Nunito'),
          bodyMedium: TextStyle(fontSize: 14, color: texte, fontFamily: 'Nunito'),
          bodySmall: TextStyle(fontSize: 12, color: grisTexte, fontFamily: 'Nunito'),
          labelSmall: TextStyle(fontSize: 11, color: gris, fontFamily: 'Nunito'),
        ),
      );
}

extension ColorExtension on Color {
  Color withOpacityValue(double opacity) => withOpacity(opacity);
}