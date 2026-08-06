import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kgoro Brand Palette — "Local first, grounded in Thaba Nchu"
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // ── Primary brand ────────────────────────────────────────────────────────
  /// Deep mountain green — primary actions, nav, identity.
  static const Color mountain     = Color(0xFF174A3A);
  /// Light green tint — selected states, chip backgrounds.
  static const Color mountainTint = Color(0xFFE6F1EC);

  // ── Highlight ────────────────────────────────────────────────────────────
  /// Warm gold — ratings, earnings, positive highlights.
  static const Color naledi       = Color(0xFFE0A72F);

  // ── Semantic ─────────────────────────────────────────────────────────────
  /// Veld green — available / open / success states.
  static const Color veld         = Color(0xFF198754);
  /// Clay / amber — pending / warning states.
  static const Color clay         = Color(0xFFC47724);
  /// Error red.
  static const Color error        = Color(0xFFB54747);

  // ── Surface & background ─────────────────────────────────────────────────
  /// Warm off-white canvas — friendlier than pure white or cold grey.
  static const Color background   = Color(0xFFF8F6F1);
  /// Raised surface (cards, sheets).
  static const Color surface      = Colors.white;

  // ── Text ─────────────────────────────────────────────────────────────────
  /// Primary text — very dark green, near-black.
  static const Color ink          = Color(0xFF1C2B26);
  /// Secondary / muted text.
  static const Color muted        = Color(0xFF68756F);
  /// Borders and dividers.
  static const Color line         = Color(0xFFDDE5DF);

  // ── Category accents (icon backgrounds only) ─────────────────────────────
  static const Color food         = Color(0xFF2D6A4F);
  static const Color liquor       = Color(0xFF6B3FA0);
  static const Color cab          = Color(0xFFB9681E);
  static const Color groceries    = Color(0xFF198754);

  // ── Legacy aliases — keep screens that reference old names compiling ──────
  static const Color primary      = mountain;
  static const Color primaryLight = Color(0xFF569CF0); // kept for gradient use
  static const Color primaryDark  = Color(0xFF0D2C54);
  static const Color success      = veld;
  static const Color warning      = clay;
  static const Color surfaceTint  = mountainTint;
  static const Color textMuted    = muted;
  static const Color night        = primaryDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    // Plus Jakarta Sans — warm, modern, legible at all sizes.
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -0.5),
      displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -0.5),
      headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3),
      headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
      titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.ink, height: 1.5),
      bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink, height: 1.5),
      bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted, height: 1.45),
      labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
      labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
      labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.mountain,
        brightness: Brightness.light,
        primary: AppColors.mountain,
        onPrimary: Colors.white,
        secondary: AppColors.naledi,
        onSecondary: AppColors.ink,
        tertiary: AppColors.veld,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),

      // ── Elevated button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mountain,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),

      // ── Outlined button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: AppColors.mountain,
          side: const BorderSide(color: AppColors.mountain),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── Text button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mountain,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      // ── Input decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mountain, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        floatingLabelStyle: const TextStyle(
          color: AppColors.mountain,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.mountainTint,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600, color: AppColors.mountain, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
      ),

      // ── Bottom navigation bar ─────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.mountainTint,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.mountain
                : AppColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.mountain
                : AppColors.muted,
            size: 22,
          ),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.surface : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.mountain : AppColors.line,
        ),
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.mountain,
      ),
    );
  }

  // ── Dark theme (preserves existing dark experience) ────────────────────────
  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D1F18),
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.mountain,
        brightness: Brightness.dark,
        primary: const Color(0xFF4CAF82),
        onPrimary: Colors.white,
        secondary: AppColors.naledi,
        onSecondary: AppColors.ink,
        surface: const Color(0xFF142419),
        onSurface: Colors.white,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0D1F18),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A2E20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF2A3F2E)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF142419),
        indicatorColor: const Color(0xFF2D6A4F),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? const Color(0xFF4CAF82) : Colors.white60,
          ),
        ),
      ),
    );
  }
}
