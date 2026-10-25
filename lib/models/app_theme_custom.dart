import 'package:flutter/material.dart';

/// Customizable color theme configuration for Math-iQ.
class AppThemeCustom {
  final String id;
  final String name;
  final String description;
  final int cost; // 0 if default / free
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color primary;
  final Color accent;
  final Color onBackground;
  final String previewEmoji;

  const AppThemeCustom({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.primary,
    required this.accent,
    required this.onBackground,
    required this.previewEmoji,
  });

  static const List<AppThemeCustom> allThemes = [
    AppThemeCustom(
      id: 'classic',
      name: 'Classic Cream',
      description: 'The signature warm tactile Math-iQ look.',
      cost: 0,
      background: Color(0xFFFFFDF5),
      surface: Color(0xFFF8F9FF),
      surfaceContainer: Color(0xFFECEDF5),
      primary: Color(0xFF005DA7),
      accent: Color(0xFFFDD73B),
      onBackground: Color(0xFF191C21),
      previewEmoji: '🎨',
    ),
    AppThemeCustom(
      id: 'dark_oled',
      name: 'Midnight OLED',
      description: 'Ultra-dark sleek aesthetic that saves battery.',
      cost: 1500,
      background: Color(0xFF121318),
      surface: Color(0xFF1A1C24),
      surfaceContainer: Color(0xFF232631),
      primary: Color(0xFF64B5F6),
      accent: Color(0xFFFFD54F),
      onBackground: Color(0xFFEDEDED),
      previewEmoji: '🌙',
    ),
    AppThemeCustom(
      id: 'cyber_neon',
      name: 'Cyberpunk Neon',
      description: 'Futuristic electric purples and glowing cyan.',
      cost: 2000,
      background: Color(0xFF130E24),
      surface: Color(0xFF1D1636),
      surfaceContainer: Color(0xFF2A204C),
      primary: Color(0xFF00E5FF),
      accent: Color(0xFFFF007F),
      onBackground: Color(0xFFF0EFFF),
      previewEmoji: '⚡',
    ),
    AppThemeCustom(
      id: 'forest_mint',
      name: 'Nordic Forest',
      description: 'Calming sage greens, earthy moss, and fresh mint.',
      cost: 1500,
      background: Color(0xFFF4F7F4),
      surface: Color(0xFFE9EFEA),
      surfaceContainer: Color(0xFFD8E4DA),
      primary: Color(0xFF2E7D32),
      accent: Color(0xFF6BCB77),
      onBackground: Color(0xFF1E2D22),
      previewEmoji: '🌿',
    ),
    AppThemeCustom(
      id: 'sunset_gold',
      name: 'Sunset Gold',
      description: 'Warm golden hues and imperial twilight amber.',
      cost: 2500,
      background: Color(0xFFFFF8EC),
      surface: Color(0xFFFDF0D5),
      surfaceContainer: Color(0xFFF6E2B8),
      primary: Color(0xFFB45309),
      accent: Color(0xFFF59E0B),
      onBackground: Color(0xFF291E0A),
      previewEmoji: '👑',
    ),
  ];

  static AppThemeCustom getById(String id) {
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => allThemes.first,
    );
  }
}
