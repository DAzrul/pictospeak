import 'package:flutter/material.dart';

class AppTheme {
  // Warna Utama (Healthcare & Pastel)
  static const Color primaryBlue = Color(0xFF0E4A8E); // Biru Perubatan (Trust)
  static const Color backgroundWhite = Color(0xFFF8FAFC); // Off-white supaya tak silau
  static const Color pastelRed = Color(0xFFFECACA); // Untuk butang 'Sakit' / SOS
  static const Color pastelYellow = Color(0xFFFEF08A); // Untuk 'Gembira'
  static const Color pastelBlue = Color(0xFFBFDBFE); // Untuk 'Sedih'
  static const Color textDark = Color(0xFF1E293B);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        background: backgroundWhite,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto', // Font paling selamat & jelas baca

      // Design seragam untuk semua butang besar dalam app
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded sikit supaya tak tajam (Child-friendly)
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}