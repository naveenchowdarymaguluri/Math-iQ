import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/challenge_level.dart';
import '../services/level_service.dart';
import '../widgets/ad_banner.dart';
import 'level_play_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  final ChallengeMode mode;
  const LevelSelectScreen({super.key, required this.mode});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final _scrollController = ScrollController();
  static const _cols = 5;
  static const _cellSize = 60.0;
  static const _gap = 10.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final current = LevelService.instance.currentLevelFor(widget.mode);
    if (current <= _cols) return;
    final row = ((current - 1) ~/ _cols).toDouble();
    final targetOffset = (row * (_cellSize + _gap)) - 100.0;
    _scrollController.animateTo(
      targetOffset.clamp(
          0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final primary = Color(mode.primaryColorValue);
    final shadow = Color(mode.shadowColorValue);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: const SafeArea(
        child: AdBanner(placement: 'levelSelectBanner'),
      ),
      body: Column(
        children: [
          _ModeHeader(mode: mode, primary: primary, shadow: shadow),
          Expanded(
            child: ListenableBuilder(
              listenable: LevelService.instance,
              builder: (context, _) {
                final svc = LevelService.instance;
                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                    crossAxisSpacing: _gap,
                    mainAxisSpacing: _gap,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    final stars = svc.starsFor(mode, level);
                    final unlocked = svc.isUnlocked(mode, level);
                    final isCurrent =
                        svc.currentLevelFor(mode) == level && unlocked;
                    return _LevelTile(
                      level: level,
                      stars: stars,
                      unlocked: unlocked,
                      isCurrent: isCurrent,
                      primary: primary,
                      onTap: unlocked
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LevelPlayScreen(
                                    mode: mode,
                                    level: level,
                                  ),
                                ),
                              );
                              if (mounted) setState(() {});
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mode header ──────────────────────────────────────────────────────────────
class _ModeHeader extends StatelessWidget {
  final ChallengeMode mode;
  final Color primary;
  final Color shadow;
  const _ModeHeader(
      {required this.mode, required this.primary, required this.shadow});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LevelService.instance,
      builder: (context, _) {
        final totalStars = LevelService.instance.totalStarsFor(mode);
        final highest = LevelService.instance.highestPlayedFor(mode);
        return Container(
          decoration: BoxDecoration(
            color: primary,
            boxShadow: [
              BoxShadow(color: shadow, offset: const Offset(0, 4), blurRadius: 0)
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
              child: Column(
                children: [
                  // Back row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Star badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$totalStars / 300',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Mode info
                  Text(mode.emoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 4),
                  Text(
                    mode.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    mode.opsLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (highest > 0)
                    Text(
                      'Best: Level $highest',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: totalStars / 300,
                      minHeight: 8,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.25),
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
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

// ─── Level tile ───────────────────────────────────────────────────────────────
class _LevelTile extends StatefulWidget {
  final int level;
  final int stars;
  final bool unlocked;
  final bool isCurrent;
  final Color primary;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.isCurrent,
    required this.primary,
    this.onTap,
  });

  @override
  State<_LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<_LevelTile> {
  bool _pressed = false;

  Color get _bgColor {
    if (!widget.unlocked) return const Color(0xFFCFCFCF);
    if (widget.stars == 3) return widget.primary.withValues(alpha: 0.12);
    if (widget.isCurrent) return widget.primary;
    if (widget.stars > 0) return widget.primary.withValues(alpha: 0.8);
    return widget.primary;
  }

  Color get _numColor {
    if (!widget.unlocked) return const Color(0xFF9E9E9E);
    if (widget.stars == 3) return widget.primary;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.unlocked;
    return GestureDetector(
      onTapDown: unlocked ? (_) => setState(() => _pressed = true) : null,
      onTapUp: unlocked
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform:
            _pressed ? Matrix4.translationValues(0, 3, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: widget.isCurrent && unlocked
              ? Border.all(color: Colors.white, width: 2.5)
              : widget.stars == 3
                  ? Border.all(color: widget.primary, width: 2)
                  : null,
          boxShadow: (_pressed || !unlocked)
              ? []
              : [
                  BoxShadow(
                    color: widget.primary.withValues(alpha: 0.4),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_rounded,
                  color: Color(0xFF9E9E9E), size: 18)
            else
              Text(
                '${widget.level}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: widget.level >= 100 ? 12 : 14,
                  fontWeight: FontWeight.w800,
                  color: _numColor,
                ),
              ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final earned = i < widget.stars;
                return Icon(
                  earned
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 9,
                  color: earned
                      ? (widget.stars == 3
                          ? widget.primary
                          : Colors.white)
                      : Colors.white.withValues(alpha: unlocked ? 0.5 : 0),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
