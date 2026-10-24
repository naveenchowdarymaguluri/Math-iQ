import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../theme/app_colors.dart';
import '../services/analytics_service.dart';
import '../services/player_data_service.dart';
import '../services/sound_service.dart';
import '../services/subscription_service.dart';
import '../widgets/dotted_background.dart';
import '../widgets/math_progress_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sfxOn = true;
  bool _musicOn = true;
  double _timeLimit = 60;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    final svc = PlayerDataService.instance;
    _sfxOn = svc.sfxOn;
    _musicOn = svc.musicOn;
    _timeLimit = svc.dailyTimeLimitMins.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return DottedBackground(
      child: Column(
        children: [
          _AppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customize your Math IQ experience.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Subscription ─────────────────────────────────────────
                  // Hidden while subscriptions are disabled for this release.
                  if (SubscriptionService.instance.subscriptionsEnabled) ...[
                    ListenableBuilder(
                      listenable: SubscriptionService.instance,
                      builder: (context, _) {
                        final sub = SubscriptionService.instance;
                        return sub.isPro
                            ? _ProActiveBanner(sub: sub)
                            : _UpgradeCard(sub: sub);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Audio ────────────────────────────────────────────────
                  _sectionHeader(Icons.volume_up_rounded, 'AUDIO'),
                  const SizedBox(height: 8),
                  _TactileCard(
                    child: Column(
                      children: [
                        _ToggleRow(
                          label: 'Sound Effects',
                          sub: 'Correct / wrong / level-up sounds',
                          value: _sfxOn,
                          onChanged: (v) {
                            setState(() => _sfxOn = v);
                            PlayerDataService.instance.saveSfx(v);
                            SoundService.instance.setSfx(v);
                            AnalyticsService.instance.logSettingChanged(
                              settingName: 'sfx',
                              newValue: v ? 'on' : 'off',
                            );
                          },
                          showDivider: true,
                        ),
                        _ToggleRow(
                          label: 'Music',
                          sub: 'Background music (coming soon)',
                          value: _musicOn,
                          onChanged: (v) {
                            setState(() => _musicOn = v);
                            PlayerDataService.instance.saveMusic(v);
                            AnalyticsService.instance.logSettingChanged(
                              settingName: 'music',
                              newValue: v ? 'on' : 'off',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Parental Controls ────────────────────────────────────
                  _sectionHeader(
                    Icons.family_restroom_rounded,
                    'PARENTAL CONTROLS',
                  ),
                  const SizedBox(height: 8),
                  _TactileCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Time Limit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_timeLimit.round()} Mins',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          MathProgressBar(
                            value: _timeLimit / 120,
                            fillColor: AppColors.mintGreen,
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: AppColors.primary,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 14,
                              ),
                              overlayColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            child: Slider(
                              value: _timeLimit,
                              min: 15,
                              max: 120,
                              divisions: 7,
                              onChanged: (v) => setState(() => _timeLimit = v),
                              onChangeEnd: (v) =>
                                  _saveTimeLimitWithAuth(v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Statistics ───────────────────────────────────────────
                  _sectionHeader(Icons.bar_chart_rounded, 'STATISTICS'),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: PlayerDataService.instance,
                    builder: (context, _) {
                      final svc = PlayerDataService.instance;
                      return _TactileCard(
                        child: Column(
                          children: [
                            _StatRow(
                              label: 'Total XP',
                              value: '${svc.totalXP} XP',
                              showDivider: true,
                            ),
                            _StatRow(
                              label: 'Current Level',
                              value: 'Level ${svc.level}',
                              showDivider: true,
                            ),
                            _StatRow(
                              label: 'Day Streak',
                              value: '${svc.streakDays} days',
                              showDivider: true,
                            ),
                            _StatRow(
                              label: 'Total Sessions',
                              value: '${svc.recentSessions.length}',
                              showDivider: true,
                            ),
                            _StatRow(
                              label: 'Achievements',
                              value: '${svc.unlockedAchievements.length} / 15',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Data ─────────────────────────────────────────────────
                  _sectionHeader(Icons.storage_rounded, 'DATA'),
                  const SizedBox(height: 8),
                  _AccountButton(
                    icon: Icons.delete_forever_rounded,
                    label: 'Reset All Progress',
                    color: AppColors.errorContainer,
                    textColor: AppColors.mathRed,
                    borderColor: AppColors.mathRed,
                    onTap: () => _confirmReset(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.creamBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Reset Progress?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.mathRed,
          ),
        ),
        content: Text(
          'This will permanently delete all your XP, levels, achievements and session history.',
          style: GoogleFonts.beVietnamPro(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mathRed,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await PlayerDataService.instance.resetAll();
              if (mounted) {
                setState(() {
                  _sfxOn = true;
                  _musicOn = true;
                  _timeLimit = 60;
                });
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Progress reset!'),
                    backgroundColor: AppColors.mintGreen,
                  ),
                );
              }
            },
            child: Text(
              'Reset',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTimeLimitWithAuth(double v) async {
    final prevLimit =
        PlayerDataService.instance.dailyTimeLimitMins.toDouble();
    if (v == prevLimit) return; // no change — skip auth
    bool authenticated = false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (canCheck) {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to change the daily time limit',
          options: const AuthenticationOptions(biometricOnly: false),
        );
      } else {
        authenticated = true; // no auth hardware — allow change
      }
    } catch (_) {
      authenticated = true; // fallback: allow change if auth errors
    }
    if (!mounted) return;
    if (authenticated) {
      await PlayerDataService.instance.saveDailyTimeLimit(v.round());
      AnalyticsService.instance.logSettingChanged(
        settingName: 'daily_time_limit',
        newValue: '${v.round()}',
      );
    } else {
      // Revert slider to previous value
      setState(() => _timeLimit = prevLimit);
    }
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.creamBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.face_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Math IQ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.settings_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable card ────────────────────────────────────────────────────────────
class _TactileCard extends StatelessWidget {
  final Widget child;
  const _TactileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.surfaceContainerHighest,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Toggle row ───────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _ToggleRow({
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub!,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(!value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 30,
                  decoration: BoxDecoration(
                    color: value
                        ? AppColors.mintGreen
                        : AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: value
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
                              offset: Offset(0, 2),
                            ),
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
        if (showDivider)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.surfaceContainerHigh,
          ),
      ],
    );
  }
}

// ─── Stat row ─────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;
  const _StatRow({
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.surfaceContainerHigh,
          ),
      ],
    );
  }
}

// ─── Account button ───────────────────────────────────────────────────────────
class _AccountButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _AccountButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  State<_AccountButton> createState() => _AccountButtonState();
}

class _AccountButtonState extends State<_AccountButton> {
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.borderColor ?? widget.color,
            width: 2,
          ),
          boxShadow: _pressed
              ? []
              : [
                  const BoxShadow(
                    color: AppColors.surfaceContainerHighest,
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pro Active Banner (shown when user has Math IQ Pro) ──────────────────────
class _ProActiveBanner extends StatelessWidget {
  final SubscriptionService sub;
  const _ProActiveBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    final entitlement = sub.proEntitlement;
    // expirationDate is a String? (ISO 8601) — null means lifetime.
    final expiryStr = entitlement?.expirationDate;
    final expiryDate = expiryStr != null ? DateTime.tryParse(expiryStr) : null;

    String statusLabel;
    if (expiryStr == null) {
      statusLabel = 'Lifetime access — no renewal needed';
    } else if (expiryDate != null) {
      statusLabel =
          'Renews ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
    } else {
      statusLabel = 'Active subscription';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005DA7), Color(0xFF2976C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PRO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSecondaryContainer,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Math IQ Pro',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(Icons.verified_rounded, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProActionButton(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Manage',
                  onTap: () => _openCustomerCenter(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProActionButton(
                  icon: Icons.help_outline_rounded,
                  label: 'Support',
                  onTap: () => _openCustomerCenter(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomerCenter(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Could not open Customer Center: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open Customer Center: $e'),
          backgroundColor: AppColors.mathRed,
        ),
      );
    }
  }
}

class _ProActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Upgrade Card (shown when user is not Pro) ────────────────────────────────
class _UpgradeCard extends StatefulWidget {
  final SubscriptionService sub;
  const _UpgradeCard({required this.sub});

  @override
  State<_UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends State<_UpgradeCard> {
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.surfaceContainerHighest,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header gradient strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF005DA7), Color(0xFF2976C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.secondaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Math IQ Pro',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Features list
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: const [
                _FeatureRow(
                  icon: Icons.block_rounded,
                  text: 'Remove all ads',
                  color: AppColors.mathRed,
                ),
                _FeatureRow(
                  icon: Icons.all_inclusive_rounded,
                  text: 'Unlock all 500+ levels',
                  color: AppColors.primary,
                ),
                _FeatureRow(
                  icon: Icons.bolt_rounded,
                  text: 'Monthly, Yearly & Lifetime plans',
                  color: AppColors.softOrange,
                ),
                _FeatureRow(
                  icon: Icons.support_agent_rounded,
                  text: 'Priority support & early features',
                  color: AppColors.mintGreen,
                ),
              ],
            ),
          ),
          // CTA Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: GestureDetector(
              onTap: widget.sub.isLoading ? null : _openPaywall,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF005DA7), Color(0xFF2976C7)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Upgrade to Pro',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Restore button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _restoring
                ? const SizedBox(
                    height: 32,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _restorePurchases,
                    child: Text(
                      'Restore Purchases',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaywall() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await RevenueCatUI.presentPaywallIfNeeded(
        'Math IQ Pro',
        displayCloseButton: true,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open paywall: $e'),
          backgroundColor: AppColors.mathRed,
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _restoring = true);
    final wasPro = await widget.sub.restorePurchases();
    if (!mounted) return;
    setState(() => _restoring = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasPro ? 'Pro access restored!' : 'No previous purchases found.',
        ),
        backgroundColor: wasPro
            ? AppColors.mintGreen
            : AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
