import 'package:flutter/material.dart';

class KalimaTheme {
  // Paleta de cores premium
  static const Color background = Color(0xFF0A0B10); // Preto obsidiana/cinema
  static const Color surface = Color(0xFF16171E); // Superfície de card escuro
  static const Color surfaceLight = Color(0xFF222430); // Card destacado / input
  
  static const Color primary = Color(0xFF8B5CF6); // Neon violeta principal
  static const Color accent = Color(0xFFEC4899); // Rosa vibrante secundário
  static const Color gold = Color(0xFFF59E0B); // Dourado luxuoso para estrelas / favoritos
  
  static const Color textPrimary = Color(0xFFF3F4F6); // Branco fosco premium
  static const Color textSecondary = Color(0xFF9CA3AF); // Cinza suave
  static const Color border = Color(0xFF2E303F); // Borda brilhante e sutil

  // Gradientes Premium
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [surface, Color(0xFF0F1015)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1F8B5CF6), // Violeta muito translúcido
      Color(0x0AEC4899), // Rosa extremamente translúcido
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Efeito de sombra brilhante (Glow)
  static List<BoxShadow> neonGlow({Color color = primary, double blur = 12.0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.4),
        blurRadius: blur,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: color.withOpacity(0.1),
        blurRadius: blur * 2,
        spreadRadius: 2,
      ),
    ];
  }

  // Estilização completa do ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
