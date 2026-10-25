import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_theme_custom.dart';
import '../models/avatar_frame.dart';
import '../services/player_data_service.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../widgets/dotted_background.dart';

class XpShopScreen extends StatefulWidget {
  const XpShopScreen({super.key});

  @override
  State<XpShopScreen> createState() => _XpShopScreenState();
}

class _XpShopScreenState extends State<XpShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppColors.mathRed : AppColors.mintGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerDataService.instance,
      builder: (context, _) {
        final svc = PlayerDataService.instance;

        return Scaffold(
          body: DottedBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _ShopAppBar(svc: svc),
                  _ShopTabBar(tabCtrl: _tabCtrl),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _PowerUpsTab(svc: svc, onSnack: _showSnack),
                        _ThemesTab(svc: svc, onSnack: _showSnack),
                        _AvatarFramesTab(svc: svc, onSnack: _showSnack),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────
class _ShopAppBar extends StatelessWidget {
  final PlayerDataService svc;
  const _ShopAppBar({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom:
              BorderSide(color: AppColors.surfaceContainerHighest, width: 3),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XP Rewards Shop',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Level ${svc.level} • ${svc.totalXP} Lifetime XP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Spendable XP balance pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.secondary, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.secondary,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${svc.spendableXP} XP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Bar ─────────────────────────────────────────────────────────────────
class _ShopTabBar extends StatelessWidget {
  final TabController tabCtrl;
  const _ShopTabBar({required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      child: TabBar(
        controller: tabCtrl,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3.5,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        tabs: const [
          Tab(text: 'Power-Ups ⚡'),
          Tab(text: 'Themes 🎨'),
          Tab(text: 'Frames 👑'),
        ],
      ),
    );
  }
}

// ─── Power-Ups Tab ───────────────────────────────────────────────────────────
class _PowerUpsTab extends StatelessWidget {
  final PlayerDataService svc;
  final void Function(String, {bool isError}) onSnack;

  const _PowerUpsTab({required this.svc, required this.onSnack});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Streak Freeze
        _ShopItemCard(
          emoji: '🛡️',
          title: 'Streak Freeze',
          subtitle:
              'Protects 1 missed day of your daily streak. Automatically activates when needed.',
          badge: 'Equipped: ${svc.streakFreezesCount} / 2',
          badgeColor: AppColors.softOrange,
          cost: PlayerDataService.streakFreezeCost,
          actionLabel: svc.streakFreezesCount >= 2 ? 'MAX EQUIPPED' : 'BUY FOR 250 XP',
          isMaxed: svc.streakFreezesCount >= 2,
          canAfford: svc.canAfford(PlayerDataService.streakFreezeCost),
          onBuy: () async {
            final ok = await svc.buyStreakFreeze();
            if (ok) {
              SoundService.instance.play(SoundType.levelUp);
              onSnack('🛡️ Streak Freeze equipped! (Total: ${svc.streakFreezesCount})');
            } else {
              SoundService.instance.play(SoundType.wrong);
              onSnack('Not enough spendable XP for Streak Freeze!', isError: true);
            }
          },
        ),
        const SizedBox(height: 14),

        // 50/50 Lifeline
        _ShopItemCard(
          emoji: '✂️',
          title: '50/50 Lifeline',
          subtitle:
              'Removes 2 wrong choices from questions in Practice or Survival Challenge modes.',
          badge: 'Owned: ${svc.lifeline5050Count}',
          badgeColor: AppColors.primary,
          cost: PlayerDataService.lifeline5050Cost,
          actionLabel: 'BUY 1x (60 XP)',
          secondaryActionLabel: '3x PACK (150 XP)',
          canAfford: svc.canAfford(PlayerDataService.lifeline5050Cost),
          onBuy: () async {
            final ok = await svc.buyLifeline5050(count: 1);
            if (ok) {
              SoundService.instance.play(SoundType.levelUp);
              onSnack('✂️ 50/50 Lifeline purchased! (Owned: ${svc.lifeline5050Count})');
            } else {
              SoundService.instance.play(SoundType.wrong);
              onSnack('Not enough spendable XP!', isError: true);
            }
          },
          onSecondaryBuy: () async {
            if (svc.spendableXP < 150) {
              SoundService.instance.play(SoundType.wrong);
              onSnack('Need 150 XP for the 3x bundle!', isError: true);
              return;
            }
            final ok = await svc.spendXP(150);
            if (ok) {
              svc.lifeline5050Count += 3;
              SoundService.instance.play(SoundType.levelUp);
              onSnack('🎉 3x 50/50 Lifelines added! (Total: ${svc.lifeline5050Count})');
            }
          },
        ),
        const SizedBox(height: 14),

        // Time Freeze Lifeline
        _ShopItemCard(
          emoji: '⏱️',
          title: 'Time Freeze (+10s)',
          subtitle:
              'Freezes timer and grants +10 bonus seconds during timed or Survival rounds.',
          badge: 'Owned: ${svc.lifelineTimeFreezeCount}',
          badgeColor: const Color(0xFF6C5CE7),
          cost: PlayerDataService.lifelineTimeFreezeCost,
          actionLabel: 'BUY 1x (75 XP)',
          secondaryActionLabel: '3x PACK (180 XP)',
          canAfford: svc.canAfford(PlayerDataService.lifelineTimeFreezeCost),
          onBuy: () async {
            final ok = await svc.buyLifelineTimeFreeze(count: 1);
            if (ok) {
              SoundService.instance.play(SoundType.levelUp);
              onSnack('⏱️ Time Freeze purchased! (Owned: ${svc.lifelineTimeFreezeCount})');
            } else {
              SoundService.instance.play(SoundType.wrong);
              onSnack('Not enough spendable XP!', isError: true);
            }
          },
          onSecondaryBuy: () async {
            if (svc.spendableXP < 180) {
              SoundService.instance.play(SoundType.wrong);
              onSnack('Need 180 XP for the 3x bundle!', isError: true);
              return;
            }
            final ok = await svc.spendXP(180);
            if (ok) {
              svc.lifelineTimeFreezeCount += 3;
              SoundService.instance.play(SoundType.levelUp);
              onSnack('🎉 3x Time Freezes added! (Total: ${svc.lifelineTimeFreezeCount})');
            }
          },
        ),
        const SizedBox(height: 14),

        // Challenge Revive Ticket info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceContainerHighest, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.mathRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mathRed, width: 2),
                ),
                child: const Center(
                  child: Text('❤️', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Challenge Second Chance (+1 Life)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Spend 150 XP directly inside Survival Mode when out of lives to continue your record run.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Themes Tab ─────────────────────────────────────────────────────────────
class _ThemesTab extends StatelessWidget {
  final PlayerDataService svc;
  final void Function(String, {bool isError}) onSnack;

  const _ThemesTab({required this.svc, required this.onSnack});

  @override
  Widget build(BuildContext context) {
    final themes = AppThemeCustom.allThemes;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: themes.length,
      separatorBuilder: (_, index) => const SizedBox(height: 14),
      itemBuilder: (context, idx) {
        final theme = themes[idx];
        final isEquipped = svc.equippedThemeId == theme.id;
        final isUnlocked = svc.unlockedThemeIds.contains(theme.id);
        final canAfford = svc.canAfford(theme.cost);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEquipped ? AppColors.primary : AppColors.surfaceContainerHighest,
              width: isEquipped ? 2.5 : 2,
            ),
            boxShadow: isEquipped
                ? const [
                    BoxShadow(
                      color: AppColors.primary,
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(theme.previewEmoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              theme.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            if (isEquipped) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.mintGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          theme.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Palette Swatches
              Row(
                children: [
                  Text(
                    'Palette: ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _Swatch(color: theme.background, label: 'BG'),
                  const SizedBox(width: 6),
                  _Swatch(color: theme.surface, label: 'Surface'),
                  const SizedBox(width: 6),
                  _Swatch(color: theme.primary, label: 'Primary'),
                  const SizedBox(width: 6),
                  _Swatch(color: theme.accent, label: 'Accent'),
                  const Spacer(),

                  // Action Button
                  if (isEquipped)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.mintGreen, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: AppColors.mintGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Equipped',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mintGreen,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isUnlocked)
                    GestureDetector(
                      onTap: () async {
                        await svc.equipTheme(theme.id);
                        SoundService.instance.play(SoundType.button);
                        onSnack('🎨 Equipped ${theme.name}!');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.onPrimaryFixedVariant,
                              offset: Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          'Equip',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () async {
                        final ok =
                            await svc.buyAndEquipTheme(theme.id, theme.cost);
                        if (ok) {
                          SoundService.instance.play(SoundType.levelUp);
                          onSnack('🎉 Unlocked & equipped ${theme.name}!');
                        } else {
                          SoundService.instance.play(SoundType.wrong);
                          onSnack('Need ${theme.cost} XP to unlock this theme!',
                              isError: true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? AppColors.secondaryContainer
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: canAfford
                                ? AppColors.secondary
                                : AppColors.surfaceContainerHighest,
                            width: 1.5,
                          ),
                          boxShadow: canAfford
                              ? const [
                                  BoxShadow(
                                    color: AppColors.secondary,
                                    offset: Offset(0, 2),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Unlock (${theme.cost} XP)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: canAfford
                                ? AppColors.onSecondaryContainer
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Avatar Frames Tab ───────────────────────────────────────────────────────
class _AvatarFramesTab extends StatelessWidget {
  final PlayerDataService svc;
  final void Function(String, {bool isError}) onSnack;

  const _AvatarFramesTab({required this.svc, required this.onSnack});

  @override
  Widget build(BuildContext context) {
    final frames = AvatarFrame.allFrames;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: frames.length,
      separatorBuilder: (_, index) => const SizedBox(height: 14),
      itemBuilder: (context, idx) {
        final frame = frames[idx];
        final isEquipped = svc.equippedFrameId == frame.id;
        final isUnlocked = svc.unlockedFrameIds.contains(frame.id);
        final canAfford = svc.canAfford(frame.cost);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEquipped ? AppColors.primary : AppColors.surfaceContainerHighest,
              width: isEquipped ? 2.5 : 2,
            ),
          ),
          child: Row(
            children: [
              // Avatar preview with frame
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryFixed,
                      border: Border.all(
                        color: frame.borderColor,
                        width: frame.borderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: frame.glowColor,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.face_rounded,
                        color: AppColors.primary, size: 30),
                  ),
                  if (frame.badgeEmoji.isNotEmpty)
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          frame.badgeEmoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      frame.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      frame.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Button
              if (isEquipped)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.mintGreen, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 15, color: AppColors.mintGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Equipped',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mintGreen,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isUnlocked)
                GestureDetector(
                  onTap: () async {
                    await svc.equipAvatarFrame(frame.id);
                    SoundService.instance.play(SoundType.button);
                    onSnack('👑 Equipped ${frame.name} frame!');
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Equip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () async {
                    final ok = await svc.buyAndEquipAvatarFrame(
                        frame.id, frame.cost);
                    if (ok) {
                      SoundService.instance.play(SoundType.levelUp);
                      onSnack('🎉 Unlocked & equipped ${frame.name} frame!');
                    } else {
                      SoundService.instance.play(SoundType.wrong);
                      onSnack('Need ${frame.cost} XP for this frame!',
                          isError: true);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? AppColors.secondaryContainer
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canAfford
                            ? AppColors.secondary
                            : AppColors.surfaceContainerHighest,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Unlock (${frame.cost} XP)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: canAfford
                            ? AppColors.onSecondaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Swatch chip ─────────────────────────────────────────────────────────────
class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  const _Swatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 1.5),
      ),
    );
  }
}

// ─── Reusable Shop Item Card ─────────────────────────────────────────────────
class _ShopItemCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final int cost;
  final String actionLabel;
  final String? secondaryActionLabel;
  final bool isMaxed;
  final bool canAfford;
  final VoidCallback onBuy;
  final VoidCallback? onSecondaryBuy;

  const _ShopItemCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.cost,
    required this.actionLabel,
    this.secondaryActionLabel,
    this.isMaxed = false,
    required this.canAfford,
    required this.onBuy,
    this.onSecondaryBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isMaxed ? null : onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isMaxed
                          ? AppColors.surfaceContainerHigh
                          : canAfford
                              ? AppColors.secondaryContainer
                              : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMaxed
                            ? AppColors.surfaceContainerHighest
                            : canAfford
                                ? AppColors.secondary
                                : AppColors.surfaceContainerHighest,
                        width: 2,
                      ),
                      boxShadow: (!isMaxed && canAfford)
                          ? const [
                              BoxShadow(
                                color: AppColors.secondary,
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        actionLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isMaxed
                              ? AppColors.outline
                              : canAfford
                                  ? AppColors.onSecondaryContainer
                                  : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (secondaryActionLabel != null && onSecondaryBuy != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onSecondaryBuy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.primary, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.primary,
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          secondaryActionLabel!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimaryFixedVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
