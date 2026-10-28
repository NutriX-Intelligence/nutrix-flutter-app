import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary & Brands
  static const Color primary = Color(0xFFBB474E); // Palette accent: buttons, highlights, active states
  static const Color primaryLight = Color(0xFFD9707A);
  static const Color brand = Color(0xFF8F1A4D); // Palette primary: logo, headings, body text
  
  // Specific UI Colors from screenshots
  static const Color purpleAction = Color(0xFFC04A74); // Secondary accent, legible in light + dark
  static const Color blueAction = Color(0xFFBB474E); // Active tab / nav / actions
  static const Color orangeOutline = Color(0xFFFDBA74); // Orange outline buttons
  static const Color textLink = Color(0xFFBB474E);
  static const Color accentPink = Color(0xFFD4688B);

  // Backgrounds
  static const Color bgLight = Color(0xFFFEFBE9); // Palette background (cream)
  static const Color bgLightCard = Color(0xFFFFFFFF); // Pure white cards
  static const Color bgDarkSurface = Color(0xFFF6F0D6); // Cream input fill

  // Text Colors
  static const Color textMain = Color(0xFF8F1A4D); // Palette primary
  static const Color textMuted = Color(0xFF7B5663);
  static const Color textDim = Color(0xFFAD949D);

  // Status
  static const Color success = Color(0xFFC04A74); // Rose-maroon: readable on cream AND near-black (palette has no green)
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFFC45C7A); // Rose, palette-harmonised

  // Health score aliases
  static const Color healthy = success;
  static const Color moderate = warning;
  static const Color unhealthy = error;

  // Macros / Analytics
  static const Color calories = Color(0xFFC9812B); // Amber
  static const Color protein = Color(0xFFC04A74);
  static const Color carbs = Color(0xFFD9A441);
  static const Color fat = Color(0xFFBB474E);
  static const Color fiber = Color(0xFFD4688B);

  // Borders
  static const Color border = Color(0xFFF0D9CC); // Soft accent tint

  // Gradient (kept for compatibility)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brand, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [bgLightCard, bgLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Color accent = blueAction;

  // Dark-theme surface/text tokens (named — previously inlined hex literals
  // scattered across app_theme.dart, or aliases that resolved to the LIGHT
  // palette by mistake).
  static const Color bgDarkScaffold = Color(0xFF0F0B0D); // Palette ALT
  static const Color bgDarkCardSurface = Color(0xFF1C1518);
  static const Color borderDark = Color(0xFF3A2B31);
  static const Color textDarkPrimary = Color(0xFFFEFBE9);
  static const Color textDarkBody = Color(0xFFEADFCB);
  static const Color textDarkSecondary = Color(0xFFB89DA6);
  static const Color textDarkTertiary = Color(0xFF8A6F79);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.blueAction,
        surface: AppColors.bgLightCard,
        error: AppColors.error,
        onSurface: AppColors.textMain,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
          letterSpacing: 0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textMain,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLightCard,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textMain),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgLightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLight, // slight off-white for inputs
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textDim,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgLightCard,
        selectedItemColor: AppColors.blueAction,
        unselectedItemColor: AppColors.textDim,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      dividerColor: AppColors.border,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgLight,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMain),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgLightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgLightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textMain,
        contentTextStyle: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : AppColors.bgLightCard),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.border),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.textMain,
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMain),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textMuted),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDarkScaffold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.blueAction,
        surface: AppColors.bgDarkCardSurface,
        error: AppColors.error,
        onSurface: AppColors.textDarkPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textDarkPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textDarkPrimary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDarkPrimary,
          letterSpacing: 0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDarkPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDarkPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textDarkBody,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textDarkSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textDarkSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDarkPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDarkCardSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDarkPrimary),
        // Was a plain, non-GoogleFonts TextStyle with -0.5 letterSpacing —
        // dark titles rendered in Roboto while light rendered Outfit.
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDarkPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgDarkCardSurface,
        elevation: 0,
        // Was 20 vs light theme's 16 — cards visibly changed shape when the
        // user toggled dark mode.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Was the same value as scaffoldBackgroundColor, which made every
        // input field render as an invisible box in dark mode.
        fillColor: AppColors.bgDarkCardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          // Was 0xFF64748B (~3.3:1 contrast on dark bg, below WCAG AA).
          color: AppColors.textDarkSecondary,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textDarkSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgDarkCardSurface,
        selectedItemColor: AppColors.blueAction,
        unselectedItemColor: AppColors.textDarkTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      dividerColor: AppColors.borderDark,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgDarkScaffold,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgDarkCardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textDarkSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgDarkCardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgDarkCardSurface,
        contentTextStyle: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textDarkPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.borderDark)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textDarkSecondary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.borderDark,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textDarkSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.borderDark),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textDarkSecondary,
        textColor: AppColors.textDarkPrimary,
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDarkPrimary),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textDarkSecondary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.borderDark,
      ),
    );
  }
}

/// Theme-aware color tokens for widgets that build custom Containers/Text
/// instead of using Material components directly (which already read from
/// Theme.of(context) automatically). `AppColors` itself is deliberately a
/// flat, brightness-independent palette — semantic/brand colors like
/// `primary`, `calories`, `error` etc. are meant to stay constant across
/// light and dark. Use this extension instead for anything that should
/// actually flip between light and dark (surfaces, page background, body
/// text, borders).
extension AppColorsX on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Page/scaffold background.
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;

  /// Card/panel surface background.
  Color get cardBg => _isDark ? AppColors.bgDarkCardSurface : AppColors.bgLightCard;

  /// Subtle input/dropdown/segmented-control background, one step off the
  /// card surface.
  Color get inputBg => _isDark ? AppColors.bgDarkScaffold : AppColors.bgLight;

  /// Primary body/heading text.
  Color get textMain => _isDark ? AppColors.textDarkPrimary : AppColors.textMain;

  /// Secondary/caption text.
  Color get textMuted => _isDark ? AppColors.textDarkSecondary : AppColors.textMuted;

  /// Dimmest text/icon tint (placeholders, disabled hints).
  Color get textDim => _isDark ? AppColors.textDarkTertiary : AppColors.textDim;

  /// Hairline borders/dividers.
  Color get borderColor => _isDark ? AppColors.borderDark : AppColors.border;
}
