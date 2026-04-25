// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Primary Greens ─────────────────────────────────────
  static const primary      = Color(0xFF1A6B3C);
  static const primaryDark  = Color(0xFF0D4A27);
  static const primaryLight = Color(0xFF2E8B57);
  static const accent       = Color(0xFF4CAF50);
  static const accentLight  = Color(0xFFE8F5E9);

  // ── Semantic ───────────────────────────────────────────
  static const healthy   = Color(0xFF2E7D32);
  static const diseased  = Color(0xFFB71C1C);
  static const warning   = Color(0xFFE65100);
  static const caution   = Color(0xFFF57F17);
  static const info      = Color(0xFF01579B);

  // ── Neutrals ───────────────────────────────────────────
  static const background  = Color(0xFFF7F9F7);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF0F4F0);
  static const border      = Color(0xFFE0E8E0);
  static const textPrimary = Color(0xFF1A2E1A);
  static const textSecond  = Color(0xFF5A7A5A);
  static const textHint    = Color(0xFF9EB89E);

  // ── Gradients ──────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF0D4A27), Color(0xFF2E8B57)],
  );
  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF1A6B3C), Color(0xFF4CAF50)],
  );
  static const gradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
  );
  static const gradientCool = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF01579B), Color(0xFF0288D1)],
  );
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary:    AppColors.primary,
        surface:    AppColors.surface,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.inter(
          fontSize: 26, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.3),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
        titleLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
        titleMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary, height: 1.6),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: AppColors.textSecond, height: 1.5),
        bodySmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w400,
          color: AppColors.textHint),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: Colors.white, letterSpacing: 0.3),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary),
        iconTheme: const IconThemeData(
            color: AppColors.textPrimary, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
              color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.inter(
            color: AppColors.textSecond, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}

// ── Shared spacing constants ────────────────────────────────────
class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

// ── Shared radius constants ─────────────────────────────────────
class AppRadius {
  static const sm  = BorderRadius.all(Radius.circular(8));
  static const md  = BorderRadius.all(Radius.circular(12));
  static const lg  = BorderRadius.all(Radius.circular(16));
  static const xl  = BorderRadius.all(Radius.circular(20));
  static const xxl = BorderRadius.all(Radius.circular(28));
  static const full= BorderRadius.all(Radius.circular(100));
}

// ── Shadow styles ───────────────────────────────────────────────
class AppShadow {
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get green => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25),
      blurRadius: 20, offset: const Offset(0, 6)),
  ];
}
