import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/dotted_background.dart';
import '../widgets/ad_banner.dart';
import '../widgets/tactile_button.dart';
import '../services/player_data_service.dart';
import 'main_shell.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      PlayerDataService.instance.markOnboardingSeen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DottedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: const [
                    _Page1(),
                    _Page2(),
                    _Page3(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const AdBanner(),
                    const SizedBox(height: 16),
                    TactileButton(
                      color: _currentPage == 2
                          ? AppColors.mintGreen
                          : AppColors.primary,
                      shadowColor: _currentPage == 2
                          ? const Color(0xFF247A33)
                          : AppColors.onPrimaryFixedVariant,
                      borderRadius: 999,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      onPressed: _next,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 32 : 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Shared logo header ───────────────────────────
class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryFixed,
            border: Border.all(color: AppColors.primary, width: 3),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.primaryFixed,
                  offset: Offset(0, 6),
                  blurRadius: 0),
            ],
          ),
          child: const Icon(Icons.psychology_rounded,
              color: AppColors.primary, size: 56),
        ),
        const SizedBox(height: 10),
        Text(
          'Math IQ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.mintGreen.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'PLAY TO LEARN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSecondaryContainer,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Page 1 ───────────────────────────
class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const _LogoHeader(),
          const SizedBox(height: 24),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.primary,
                        offset: Offset(4, 4),
                        blurRadius: 0),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.calculate_rounded,
                            size: 72, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to the\nWorld of Numbers!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkPurple,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Unlock your brain's superpower with fun games, daily challenges, and amazing rewards.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        color: AppColors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -12,
                right: -12,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.softOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0xFFCC7539),
                          offset: Offset(0, 4),
                          blurRadius: 0),
                    ],
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
              Positioned(
                bottom: -12,
                left: -12,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate,
                      color: AppColors.onSecondaryContainer, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────── Page 2 ───────────────────────────
class _Page2 extends StatelessWidget {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const _LogoHeader(),
          const SizedBox(height: 20),
          Text(
            'Unlock Daily Quests!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPurple),
          ),
          const SizedBox(height: 8),
          Text(
            'Turn your learning into an adventure. Earn XP for every puzzle!',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.surfaceContainerHighest, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.surfaceContainerHighest,
                    offset: Offset(0, 4),
                    blurRadius: 0)
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: AppColors.softOrange, size: 20),
                    const SizedBox(width: 8),
                    Text('DAILY QUESTS',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('2/3 DONE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _QuestRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.mintGreen,
                    title: 'Addition Master',
                    progressText: '10/10',
                    progress: 1.0,
                    done: true),
                const Divider(height: 24),
                _QuestRow(
                    icon: Icons.timer_rounded,
                    color: AppColors.primary,
                    title: 'Speed Runner',
                    progressText: '7/10',
                    progress: 0.7,
                    done: false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.inkPurple,
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT XP',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('1,250',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String progressText;
  final double progress;
  final bool done;

  const _QuestRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.progressText,
    required this.progress,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(progressText,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

// ─────────────────────────── Page 3 ───────────────────────────
class _Page3 extends StatelessWidget {
  const _Page3();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const _LogoHeader(),
          const SizedBox(height: 20),
          Text(
            'Collect All Stickers!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPurple),
          ),
          const SizedBox(height: 8),
          Text(
            'Master math challenges to fill your book with magical rewards.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5),
          ),
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.smart_toy_rounded,
                          size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 14),
                    Text('Math Mage',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primary)),
                    Text('Unlocked at Level 5',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Positioned(
                top: -10,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('NEW!',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSecondaryContainer)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StickerBox(
                    icon: Icons.rocket_launch_rounded,
                    color: AppColors.softOrange,
                    label: 'Star Voyager',
                    locked: false),
              ),
              const SizedBox(width: 12),
              const Expanded(child: _StickerBox(locked: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: _StickerBox(locked: true)),
              const SizedBox(width: 12),
              Expanded(
                child: _StickerBox(
                    icon: Icons.category_rounded,
                    color: AppColors.mintGreen,
                    label: 'Shape Pro',
                    locked: false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mintGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.mintGreen, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.mintGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You've already earned your first 2 stickers during training!",
                    style: GoogleFonts.beVietnamPro(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StickerBox extends StatelessWidget {
  final IconData? icon;
  final Color? color;
  final String? label;
  final bool locked;

  const _StickerBox({this.icon, this.color, this.label, this.locked = false});

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.surfaceContainerHighest, width: 2),
        ),
        child: Column(
          children: [
            Icon(Icons.lock_rounded,
                color: AppColors.outlineVariant, size: 32),
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color!.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon!, color: color!, size: 32),
          const SizedBox(height: 8),
          Text(label!,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color!)),
        ],
      ),
    );
  }
}
