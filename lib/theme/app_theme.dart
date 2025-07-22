// ═══════════════════════════════════════════════════════════════
// HYPERTRACK DESIGN SYSTEM
// PURPOSE: Monotone outlines + colorful vector icons aesthetic
// CONCEPT: Clean minimalist base with functional color accents
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class HyperTrackTheme {
  // ─────────────────────────────────────────────────────────────
  // COLOR PALETTE
  // ─────────────────────────────────────────────────────────────

  // MONOTONE BASE (outlines, text, structure)
  static const Color darkGrey = Color(0xFF2D3436);
  static const Color mediumGrey = Color(0xFF636E72);
  static const Color lightGrey = Color(0xFFB2BEC3);
  static const Color paleGrey = Color(0xFFDDD6FE);
  static const Color almostWhite = Color(0xFFFDFCFF);

  // FUNCTIONAL COLOR ICONS (vibrant accents)
  static const Color primaryBlue = Color(0xFF0984E3); // Main actions
  static const Color successGreen = Color(0xFF00B894); // Completed, positive
  static const Color warningOrange = Color(0xFFE17055); // Alerts, attention
  static const Color exerciseBlue = Color(0xFF6C5CE7); // Exercise related
  static const Color timerRed = Color(0xFFE84393); // Timer, urgent
  static const Color statsGold = Color(0xFFFDAB3D); // Statistics, achievements

  // ─────────────────────────────────────────────────────────────
  // ICON COLOR MAPPING (semantic colors)
  // ─────────────────────────────────────────────────────────────

  static const Map<String, Color> iconColors = {
    // Navigation
    'home': primaryBlue,
    'exercises': exerciseBlue,
    'gyms': successGreen,
    'stats': statsGold,

    // Exercise Functions
    'weight': exerciseBlue,
    'reps': successGreen,
    'timer': timerRed,
    'settings': mediumGrey,

    // Data & Progress
    'graph': statsGold,
    'trend': primaryBlue,
    'record': successGreen,
    'history': mediumGrey,

    // Actions
    'add': successGreen,
    'save': primaryBlue,
    'delete': warningOrange,
    'edit': exerciseBlue,
  };

  // ─────────────────────────────────────────────────────────────
  // COMPONENT THEMES
  // ─────────────────────────────────────────────────────────────

  // OUTLINE STYLES (monotone base)
  static BoxDecoration get cardOutline => BoxDecoration(
    border: Border.all(color: lightGrey, width: 1),
    borderRadius: BorderRadius.circular(8),
    color: Colors.white,
  );

  static BoxDecoration get containerOutline => BoxDecoration(
    border: Border.all(color: mediumGrey, width: 1.5),
    borderRadius: BorderRadius.circular(12),
    color: almostWhite,
  );

  static BoxDecoration get inputOutline => BoxDecoration(
    border: Border.all(color: lightGrey, width: 1),
    borderRadius: BorderRadius.circular(6),
    color: Colors.white,
  );

  // TYPOGRAPHY (monotone text hierarchy)
  static const TextStyle headerText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkGrey,
    letterSpacing: -0.5,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: mediumGrey,
    height: 1.4,
  );

  static const TextStyle captionText = TextStyle(
    fontSize: 12,
    color: lightGrey,
    letterSpacing: 0.5,
  );

  // ─────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────

  static Color getIconColor(String iconType) {
    return iconColors[iconType] ?? mediumGrey;
  }

  static Widget coloredIcon(
    IconData icon,
    String iconType, {
    double size = 20,
  }) {
    return Icon(icon, color: getIconColor(iconType), size: size);
  }

  static Widget outlinedCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: cardOutline,
      child: child,
    );
  }

  static Widget themedContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: containerOutline,
      child: child,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FLUTTER THEME INTEGRATION
  // ─────────────────────────────────────────────────────────────

  static ThemeData get theme => ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: almostWhite,
    cardColor: Colors.white,
    useMaterial3: true,

    // App Bar Theme (monotone)
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: darkGrey,
      elevation: 1,
      shadowColor: lightGrey,
      titleTextStyle: headerText,
    ),

    // Text Theme (monotone hierarchy)
    textTheme: const TextTheme(
      headlineSmall: headerText,
      bodyMedium: bodyText,
      bodySmall: captionText,
    ),

    // Button Themes (functional colors)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Input Themes (monotone outlines)
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: lightGrey),
        borderRadius: BorderRadius.circular(6),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primaryBlue, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}
