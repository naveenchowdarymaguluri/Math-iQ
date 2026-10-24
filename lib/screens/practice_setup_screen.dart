import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/quiz_question.dart';
import '../widgets/dotted_background.dart';
import '../widgets/ad_banner.dart';
import '../widgets/tactile_button.dart';
import 'gameplay_screen.dart';

class PracticeSetupScreen extends StatefulWidget {
  const PracticeSetupScreen({super.key});

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  Difficulty _difficulty = Difficulty.easy;
  final Set<Operation> _ops = {Operation.addition};
  int _rangeStart = 1;
  int _rangeEnd = 99;
  bool _timerEnabled = false; // OFF by default for relaxed unlimited practice

  final _startCtrl = TextEditingController(text: '1');
  final _endCtrl = TextEditingController(text: '99');

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  void _play() {
    _rangeStart = int.tryParse(_startCtrl.text) ?? 1;
    _rangeEnd = int.tryParse(_endCtrl.text) ?? 99;
    if (_ops.isEmpty) return;

    // 0 = no timer; otherwise Easy=15s, Medium=12s, Hard=10s
    final secs = _timerEnabled
        ? switch (_difficulty) {
            Difficulty.easy => 15,
            Difficulty.medium => 12,
            Difficulty.hard => 10,
          }
        : 0;

    // Hard mode → type the answer instead of choosing from options
    final useKeyboard = _difficulty == Difficulty.hard;

    final opSymbol = switch (_ops.first) {
      Operation.addition => '+',
      Operation.subtraction => '−',
      Operation.multiplication => '×',
      Operation.division => '÷',
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameplayScreen(
          isUnlimited: true,
          operations: _ops.toList(),
          difficulty: _difficulty,
          rangeStart: _rangeStart,
          rangeEnd: _rangeEnd,
          secondsPerQuestion: secs,
          useNumberKeyboard: useKeyboard,
          mode: 'Practice $opSymbol',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DottedBackground(
        child: Column(
          children: [
            _AppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Mode',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkPurple,
                      ),
                    ),
                    Text(
                      'Level up your math skills!',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('SELECT DIFFICULTY'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _DiffBtn(
                          label: 'Easy',
                          color: AppColors.secondaryContainer,
                          textColor: AppColors.onSecondaryContainer,
                          shadow: AppColors.secondary,
                          selected: _difficulty == Difficulty.easy,
                          onTap: () =>
                              setState(() => _difficulty = Difficulty.easy),
                        ),
                        const SizedBox(width: 12),
                        _DiffBtn(
                          label: 'Medium',
                          color: AppColors.softOrange,
                          textColor: Colors.white,
                          shadow: AppColors.tertiary,
                          selected: _difficulty == Difficulty.medium,
                          onTap: () =>
                              setState(() => _difficulty = Difficulty.medium),
                        ),
                        const SizedBox(width: 12),
                        _DiffBtn(
                          label: 'Hard',
                          color: AppColors.mathRed,
                          textColor: Colors.white,
                          shadow: const Color(0xFF960000),
                          selected: _difficulty == Difficulty.hard,
                          onTap: () =>
                              setState(() => _difficulty = Difficulty.hard),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Timer toggle ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.surfaceContainerHighest,
                            width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_rounded,
                              color: _timerEnabled
                                  ? AppColors.softOrange
                                  : AppColors.onSurfaceVariant,
                              size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Per-question timer',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                Text(
                                  _timerEnabled
                                      ? 'Race the clock on each question'
                                      : 'Relaxed mode — take your time',
                                  style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _timerEnabled = !_timerEnabled),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _timerEnabled
                                    ? AppColors.softOrange
                                    : AppColors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  alignment: _timerEnabled
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2))
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('NUMBER RANGE'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberInput(
                            label: 'Starting Number',
                            controller: _startCtrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _NumberInput(
                            label: 'Ending Number',
                            controller: _endCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('PICK YOUR POWER-UP'),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          _OpButton(
                              symbol: '+',
                              op: Operation.addition,
                              selected: _ops.contains(Operation.addition),
                              onTap: () => _toggleOp(Operation.addition)),
                          _OpButton(
                              symbol: '−',
                              op: Operation.subtraction,
                              selected: _ops.contains(Operation.subtraction),
                              onTap: () => _toggleOp(Operation.subtraction)),
                          _OpButton(
                              symbol: '×',
                              op: Operation.multiplication,
                              selected: _ops.contains(Operation.multiplication),
                              onTap: () => _toggleOp(Operation.multiplication)),
                          _OpButton(
                              symbol: '÷',
                              op: Operation.division,
                              selected: _ops.contains(Operation.division),
                              onTap: () => _toggleOp(Operation.division)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.creamBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primaryFixed,
                            width: 3,
                            style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                    color: AppColors.onPrimaryFixedVariant,
                                    offset: Offset(0, 4),
                                    blurRadius: 0)
                              ],
                            ),
                            child: const Icon(Icons.lightbulb_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MATH TIP',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(
                                  'Try adding the tens first: 20 + 10 = 30, then add the ones!',
                                  style: GoogleFonts.beVietnamPro(
                                      fontSize: 13,
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(child: AdBanner()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TactileButton(
          color: AppColors.mintGreen,
          shadowColor: const Color(0xFF247A33),
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 20),
          onPressed: _play,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 40),
              const SizedBox(width: 8),
              Text(
                'PLAY',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _toggleOp(Operation op) {
    setState(() {
      if (_ops.contains(op)) {
        if (_ops.length > 1) _ops.remove(op);
      } else {
        _ops.add(op);
      }
    });
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.outline,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(
                color: AppColors.surfaceContainerHighest, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              'Math IQ',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
            const Spacer(),
            const Icon(Icons.stars_rounded,
                color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }
}

class _DiffBtn extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color shadow;
  final bool selected;
  final VoidCallback onTap;

  const _DiffBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.shadow,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_DiffBtn> createState() => _DiffBtnState();
}

class _DiffBtnState extends State<_DiffBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: _pressed
              ? Matrix4.translationValues(0, 4, 0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            border: widget.selected
                ? Border.all(color: AppColors.primary, width: 3)
                : null,
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: widget.shadow,
                      offset: const Offset(0, 6),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _OpButton extends StatefulWidget {
  final String symbol;
  final Operation op;
  final bool selected;
  final VoidCallback onTap;

  const _OpButton({
    required this.symbol,
    required this.op,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_OpButton> createState() => _OpButtonState();
}

class _OpButtonState extends State<_OpButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(0, 4, 0)
            : Matrix4.identity(),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: widget.selected
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary,
              width: 2),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(
                    color: AppColors.onPrimaryFixedVariant,
                    offset: Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.symbol,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: widget.selected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _NumberInput({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.outline,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                  color: AppColors.surfaceContainerHighest, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 3),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                  color: AppColors.surfaceContainerHighest, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
