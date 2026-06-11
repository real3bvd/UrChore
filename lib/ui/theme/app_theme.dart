import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF7F3EE);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardWarm = Color(0xFFFDF8F2);

  // Greens
  static const Color primary = Color(0xFF5C8B6E);
  static const Color primaryDark = Color(0xFF3D6B53);
  static const Color primaryLight = Color(0xFFD6E8DE);
  static const Color accent = Color(0xFF8FBC9B);

  // Text
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textMedium = Color(0xFF6B6B6B);
  static const Color textLight = Color(0xFFAAAAAA);

  // Status
  static const Color done = Color(0xFF5C8B6E);
  static const Color pending = Color(0xFFF0A500);
  static const Color overdue = Color(0xFFD96C5B);

  // Border / divider
  static const Color border = Color(0xFFE8E2DA);
}

class AppTheme {
  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        background: AppColors.background,
        surface: AppColors.card,
        surfaceWarm: AppColors.cardWarm,
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        text: AppColors.textDark,
        textMuted: AppColors.textMedium,
        textSubtle: AppColors.textLight,
        border: AppColors.border,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        background: const Color(0xFF191816),
        surface: const Color(0xFF24221F),
        surfaceWarm: const Color(0xFF2B2824),
        primary: const Color(0xFF8DB89B),
        primaryContainer: const Color(0xFF294536),
        onPrimaryContainer: const Color(0xFFC7E7D1),
        text: const Color(0xFFF3EEE7),
        textMuted: const Color(0xFFC3BBB1),
        textSubtle: const Color(0xFF938C84),
        border: const Color(0xFF3D3934),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceWarm,
    required Color primary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color text,
    required Color textMuted,
    required Color textSubtle,
    required Color border,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: brightness == Brightness.dark
          ? const Color(0xFF102318)
          : Colors.white,
      secondary: brightness == Brightness.dark
          ? const Color(0xFFA8CCB2)
          : AppColors.accent,
      surface: surface,
      surfaceContainerLow: surfaceWarm,
      surfaceContainer: surfaceWarm,
      surfaceContainerHigh: border,
      onSurface: text,
      onSurfaceVariant: textMuted,
      outline: textSubtle,
      outlineVariant: border,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      error: brightness == Brightness.dark
          ? const Color(0xFFEF8B7D)
          : AppColors.overdue,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.dmSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: text,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSubtle,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        iconTheme: IconThemeData(color: text),
        systemOverlayStyle: (brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(
          statusBarColor: background,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWarm,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(color: textMuted),
        hintStyle: GoogleFonts.dmSans(color: textSubtle),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),
      iconTheme: IconThemeData(color: textMuted),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: textSubtle,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            brightness == Brightness.dark ? const Color(0xFFF0EAE2) : text,
        contentTextStyle: GoogleFonts.dmSans(
          color: brightness == Brightness.dark
              ? const Color(0xFF25221F)
              : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
