import 'package:flutter/material.dart';

class AppTheme {
  // Medical Theme Colors - Light Mode
  static const Color primaryColor = Color(0xFF2E7D84); // Teal blue
  static const Color secondaryColor = Color(0xFF4CAF50); // Medical green
  static const Color lightBackgroundColor =
      Color(0xFFF8F9FA); // Clean white/gray
  static const Color errorColor = Color(0xFFF44336); // Red for validation
  static const Color successColor =
      Color(0xFF4CAF50); // Green for confirmations
  static const Color lightCardColor = Colors.white;
  static const Color lightShadowColor = Color(0x1A000000);

  // Medical Theme Colors - Dark Mode
  static const Color darkPrimaryColor =
      Color(0xFF4A9AA2); // Lighter teal for dark mode
  static const Color darkSecondaryColor =
      Color(0xFF66BB6A); // Lighter green for dark mode
  static const Color darkBackgroundColor =
      Color(0xFF121212); // Material dark background
  static const Color darkSurfaceColor = Color(0xFF1E1E1E); // Dark surface
  static const Color darkCardColor = Color(0xFF2D2D2D); // Dark card
  static const Color darkShadowColor = Color(0x40000000);

  // Text Colors - Light Mode
  static const Color lightPrimaryTextColor = Color(0xFF212121);
  static const Color lightSecondaryTextColor = Color(0xFF757575);
  static const Color lightHintTextColor = Color(0xFFBDBDBD);

  // Text Colors - Dark Mode
  static const Color darkPrimaryTextColor = Color(0xFFE0E0E0);
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
  static const Color darkHintTextColor = Color(0xFF6F6F6F);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2E7D84),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightCardColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: lightCardColor,
        elevation: 2,
        shadowColor: lightShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: lightHintTextColor),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: lightSecondaryTextColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: lightPrimaryTextColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: lightPrimaryTextColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: lightPrimaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: lightPrimaryTextColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: lightPrimaryTextColor,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: lightSecondaryTextColor,
          fontSize: 12,
        ),
        titleMedium: TextStyle(
          color: lightPrimaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: lightPrimaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryColor,
        brightness: Brightness.dark,
        primary: darkPrimaryColor,
        secondary: darkSecondaryColor,
        surface: darkSurfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: darkCardColor,
        elevation: 4,
        shadowColor: darkShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkSecondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: darkHintTextColor),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: darkPrimaryColor,
        unselectedLabelColor: darkSecondaryTextColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: darkPrimaryColor, width: 2),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkSurfaceColor,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: darkPrimaryTextColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: darkPrimaryTextColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: darkPrimaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: darkPrimaryTextColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: darkPrimaryTextColor,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: darkSecondaryTextColor,
          fontSize: 12,
        ),
        titleMedium: TextStyle(
          color: darkPrimaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: darkPrimaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Custom button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

  // Custom decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: lightCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: lightShadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get darkCardDecoration => BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: darkShadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get primaryGradientDecoration => const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, Color(0xFF1E5A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static BoxDecoration get darkPrimaryGradientDecoration => const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkPrimaryColor, Color(0xFF2A6065)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
}
