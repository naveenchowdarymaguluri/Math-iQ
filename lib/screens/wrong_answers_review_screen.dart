import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wrong_answer_item.dart';
import '../services/sound_service.dart';
import '../widgets/ad_banner.dart';

class WrongAnswersReviewScreen extends StatefulWidget {
  final List<WrongAnswerItem> wrongAnswers;
  const WrongAnswersReviewScreen({super.key, required this.wrongAnswers});

  @override
  State<WrongAnswersReviewScreen> createState() =>
      _WrongAnswersReviewScreenState();
}

class _WrongAnswersReviewScreenState extends State<WrongAnswersReviewScreen>
    with TickerProviderStateMixin {
  int _current = 0;
  int _solvedCorrectly = 0;
  String _typedAnswer = '';
  bool _answered = false;
  bool? _wasCorrect;
  bool _allDone = false;

  // Per-card entrance animation
  late AnimationController _cardCtrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_answered || _typedAnswer.isEmpty) return;
    final item = widget.wrongAnswers[_current];
    final typed = int.tryParse(_typedAnswer);
    final correct = typed != null && typed == item.correctAnswer;

    setState(() {
      _answered = true;
      _wasCorrect = correct;
    });

    if (correct) {
      _solvedCorrectly++;
      SoundService.instance.play(SoundType.correct);
      HapticFeedback.lightImpact();
    } else {
      SoundService.instance.play(SoundType.wrong);
      HapticFeedback.heavyImpact();
    }

    Future.delayed(const Duration(milliseconds: 1200), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_current + 1 >= widget.wrongAnswers.length) {
      setState(() => _allDone = true);
      SoundService.instance.play(SoundType.levelUp);
      return;
    }
    _cardCtrl.reset();
    setState(() {
      _current++;
      _answered = false;
      _wasCorrect = null;
      _typedAnswer = '';
    });
    _cardCtrl.forward();
  }

  void _skip() {
    if (_answered) { _advance(); return; }
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      bottomNavigationBar: const SafeArea(
        child: AdBanner(placement: 'reviewBanner'),
      ),
      body: SafeArea(
        child: _allDone ? _buildSummary() : _buildReview(),
      ),
    );
  }

  Widget _buildReview() {
    final item = widget.wrongAnswers[_current];
    final total = widget.wrongAnswers.length;

    Color boxBg = Colors.white;
    Color boxBorder = const Color(0xFFE0E0E0);
    if (_answered && _wasCorrect == true) {
      boxBg = const Color(0xFF4CAF50);
      boxBorder = const Color(0xFF2E7D32);
    } else if (_answered && _wasCorrect == false) {
      boxBg = const Color(0xFFFFEBEE);
      boxBorder = const Color(0xFFE53935);
    }

    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFF6A1B9A),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🔁  Review Mistakes  ·  ${_current + 1}/$total',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _buildProgress(_current + 1, total),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Original wrong info
                    if (item.givenAnswer != null)
                      _WrongBadge(
                        given: item.givenAnswer!,
                        correct: item.correctAnswer,
                      )
                    else
                      _TimeoutBadge(correct: item.correctAnswer),

                    const SizedBox(height: 20),

                    // Question card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: const Color(0xFF6A1B9A).withValues(alpha: 0.25),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                            offset: const Offset(0, 8),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Text(
                        item.questionText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Answer display
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: boxBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: boxBorder, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: boxBorder.withValues(alpha: 0.4),
                              offset: const Offset(0, 4),
                              blurRadius: 0),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _typedAnswer.isEmpty ? '_' : _typedAnswer,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: _typedAnswer.isEmpty
                                    ? const Color(0xFFBDBDBD)
                                    : _answered && _wasCorrect == true
                                        ? Colors.white
                                        : _answered && _wasCorrect == false
                                            ? const Color(0xFFE53935)
                                            : const Color(0xFF1A1A1A),
                              ),
                            ),
                            if (_answered && _wasCorrect == false) ...[
                              const SizedBox(width: 14),
                              Text(
                                '→ ${item.correctAnswer}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Numpad
                    if (!_answered) ...[
                      _numRow(['7', '8', '9']),
                      const SizedBox(height: 8),
                      _numRow(['4', '5', '6']),
                      const SizedBox(height: 8),
                      _numRow(['1', '2', '3']),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _KeyBtn(
                              label: '⌫',
                              bg: const Color(0xFFFF9800)
                                  .withValues(alpha: 0.15),
                              fg: const Color(0xFFFF9800),
                              onTap: () {
                                if (_typedAnswer.isNotEmpty) {
                                  setState(() => _typedAnswer = _typedAnswer
                                      .substring(
                                          0, _typedAnswer.length - 1));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KeyBtn(
                                label: '0',
                                onTap: () {
                                  if (_typedAnswer.length < 6) {
                                    setState(() => _typedAnswer += '0');
                                  }
                                }),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KeyBtn(
                              label: '✓',
                              bg: _typedAnswer.isEmpty
                                  ? const Color(0xFFEEEEEE)
                                  : const Color(0xFF4CAF50),
                              fg: _typedAnswer.isEmpty
                                  ? const Color(0xFF9E9E9E)
                                  : Colors.white,
                              onTap: _typedAnswer.isEmpty ? null : _submit,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Skip / next button after answer
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _skip,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A1B9A),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0xFF4A148C),
                                  offset: Offset(0, 4),
                                  blurRadius: 0)
                            ],
                          ),
                          child: Text(
                            _current + 1 < widget.wrongAnswers.length
                                ? 'Next →'
                                : 'See Summary',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final total = widget.wrongAnswers.length;
    final pct =
        total > 0 ? (_solvedCorrectly / total * 100).round() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pct >= 80 ? '🎉' : pct >= 50 ? '💪' : '📚',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              pct >= 80 ? 'Great improvement!' : 'Keep practising!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_solvedCorrectly / $total mistakes corrected  ($pct%)',
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                color: const Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0xFF4A148C),
                        offset: Offset(0, 4),
                        blurRadius: 0)
                  ],
                ),
                child: Text(
                  'Back to Results',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(int current, int total) {
    return Row(
      children: List.generate(total, (i) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < current
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  Widget _numRow(List<String> digits) => Row(
        children: digits.asMap().entries.expand((e) {
          return [
            if (e.key > 0) const SizedBox(width: 8),
            Expanded(
              child: _KeyBtn(
                label: e.value,
                onTap: () {
                  if (!_answered && _typedAnswer.length < 6) {
                    setState(() => _typedAnswer += e.value);
                  }
                },
              ),
            ),
          ];
        }).toList(),
      );
}

// ── Badge: what was answered wrong ────────────────────────────────────────────
class _WrongBadge extends StatelessWidget {
  final int given;
  final int correct;
  const _WrongBadge({required this.given, required this.correct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.close_rounded, color: Color(0xFFE53935), size: 18),
          const SizedBox(width: 6),
          Text(
            'You answered: $given',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded,
              color: Color(0xFF9E9E9E), size: 16),
          const SizedBox(width: 8),
          Text(
            'Try again!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeoutBadge extends StatelessWidget {
  final int correct;
  const _TimeoutBadge({required this.correct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_off_rounded,
              color: Color(0xFFFF9800), size: 18),
          const SizedBox(width: 6),
          Text(
            'Ran out of time — try now!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Key button (shared with level_play) ──────────────────────────────────────
class _KeyBtn extends StatefulWidget {
  final String label;
  final Color? bg;
  final Color? fg;
  final VoidCallback? onTap;
  const _KeyBtn({required this.label, this.bg, this.fg, this.onTap});

  @override
  State<_KeyBtn> createState() => _KeyBtnState();
}

class _KeyBtnState extends State<_KeyBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.bg ?? const Color(0xFFF5F5F5);
    final fg = widget.fg ?? const Color(0xFF1A1A1A);
    final disabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform:
            _pressed ? Matrix4.translationValues(0, 4, 0) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bg.withValues(alpha: 0.7), width: 1.5),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                      color: bg.withValues(alpha: 0.5),
                      offset: const Offset(0, 4),
                      blurRadius: 0),
                ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: disabled ? const Color(0xFFBDBDBD) : fg,
            ),
          ),
        ),
      ),
    );
  }
}
