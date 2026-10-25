import 'package:flutter/material.dart';

/// Customizable prestige avatar frames unlockable with spendable XP.
class AvatarFrame {
  final String id;
  final String name;
  final String description;
  final int cost;
  final Color borderColor;
  final Color glowColor;
  final String badgeEmoji;
  final double borderWidth;

  const AvatarFrame({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.borderColor,
    required this.glowColor,
    required this.badgeEmoji,
    this.borderWidth = 3.0,
  });

  static const List<AvatarFrame> allFrames = [
    AvatarFrame(
      id: 'none',
      name: 'Standard Ring',
      description: 'The clean default player border.',
      cost: 0,
      borderColor: Color(0xFF005DA7),
      glowColor: Colors.transparent,
      badgeEmoji: '',
      borderWidth: 2.5,
    ),
    AvatarFrame(
      id: 'bronze_gear',
      name: 'Bronze Gear',
      description: 'Forged for aspiring problem solvers.',
      cost: 400,
      borderColor: Color(0xFFCD7F32),
      glowColor: Color(0x66CD7F32),
      badgeEmoji: '⚙️',
      borderWidth: 3.5,
    ),
    AvatarFrame(
      id: 'gold_crown',
      name: 'Royal Crown',
      description: 'Worn by royalty of mental arithmetic.',
      cost: 800,
      borderColor: Color(0xFFFFD700),
      glowColor: Color(0x88FFD700),
      badgeEmoji: '👑',
      borderWidth: 4.0,
    ),
    AvatarFrame(
      id: 'neon_flame',
      name: 'Blazing Flame',
      description: 'Radiates the heat of legendary daily streaks.',
      cost: 1200,
      borderColor: Color(0xFFFF5722),
      glowColor: Color(0x99FF5722),
      badgeEmoji: '🔥',
      borderWidth: 4.0,
    ),
    AvatarFrame(
      id: 'diamond_star',
      name: 'Celestial Diamond',
      description: 'The ultimate prestige frame of grandmasters.',
      cost: 2000,
      borderColor: Color(0xFF00E5FF),
      glowColor: Color(0xAA00E5FF),
      badgeEmoji: '💎',
      borderWidth: 4.5,
    ),
  ];

  static AvatarFrame getById(String id) {
    return allFrames.firstWhere(
      (f) => f.id == id,
      orElse: () => allFrames.first,
    );
  }
}
