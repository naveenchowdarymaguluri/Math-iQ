// ignore_for_file: avoid_print
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';
import 'subscription_service.dart';

// ─── Ad Unit IDs ──────────────────────────────────────────────────────────────
/// All AdMob unit IDs live here.
/// Google AdMob unit IDs (Android / Play Store only).
/// Debug builds use Google's official test IDs; release builds use the real
/// production IDs from the AdMob dashboard. All ads are Google AdMob — there
/// are no direct/sponsor ad units.
class AdUnitIds {
  AdUnitIds._();

  // ── Official Google test IDs (used automatically in debug builds) ───────────
  static const _testBanner       = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded     = 'ca-app-pub-3940256099942544/5224354917';

  // ── Production IDs (Google AdMob — Android) ─────────────────────────────────
  static const _prodBanner       = 'ca-app-pub-8752701784048954/2625768492';
  static const _prodInterstitial = 'ca-app-pub-8752701784048954/8677839827';
  static const _prodRewarded     = 'ca-app-pub-8752701784048954/8566244902';

  static bool get _debug => kDebugMode;

  static String get banner       => _debug ? _testBanner       : _prodBanner;
  static String get interstitial => _debug ? _testInterstitial : _prodInterstitial;
  static String get rewarded     => _debug ? _testRewarded     : _prodRewarded;
}

// ─── Ad placement labels (for analytics / logging) ────────────────────────────
enum AdPlacement {
  // Core banners (original)
  homeBanner,
  levelSelectBanner,
  practiceResultsBanner,
  challengeResultsBanner,
  recordsBanner,
  levelInterstitial,
  challengeInterstitial,
  levelFailedRewarded,
  // Expanded banner coverage
  achievementsBanner,
  stickerBanner,
  dailyQuestsBanner,
  flagQuizBanner,
  reviewBanner,
  levelPlayBanner,
  levelResultsBanner,
  challengeBanner,
  shellBanner,
  practiceGameplay,
  // Full-screen formats
  practiceInterstitial,
  challengeDoubleXpRewarded,
  milestoneRewarded,
}

// ─── Revenue estimate ─────────────────────────────────────────────────────────
class AdRevenueEstimate {
  final double bannerDaily;
  final double interstitialDaily;
  final double rewardedDaily;

  const AdRevenueEstimate({
    required this.bannerDaily,
    required this.interstitialDaily,
    required this.rewardedDaily,
  });

  double get totalDaily   => bannerDaily + interstitialDaily + rewardedDaily;
  double get totalMonthly => totalDaily * 30;
  double get totalYearly  => totalDaily * 365;
}

// ─── Ad strategy spec (one per placement) ────────────────────────────────────
class AdSpec {
  final AdPlacement placement;
  final String type;       // "Banner" / "Interstitial" / "Rewarded" / "Native"
  final String trigger;    // when it fires
  final String rationale;  // why it's here
  final double expectedCPM;
  final String size;

  const AdSpec({
    required this.placement,
    required this.type,
    required this.trigger,
    required this.rationale,
    required this.expectedCPM,
    required this.size,
  });
}

// ─── Core service ─────────────────────────────────────────────────────────────
class AdService {
  static final instance = AdService._();
  AdService._();

  // Frequency state
  int _sessionCompletions     = 0;
  int _totalCompletions       = 0;   // lifetime-of-session completions
  bool _rewardedOfferPending  = false;
  DateTime? _lastInterstitial;
  // Short gap only guards against back-to-back full-screen ads; with levels
  // taking ~1 min each, "every 3 completions" fires reliably.
  static const _interstitialGap    = Duration(minutes: 1);
  static const _interstitialEveryN = 3;  // interstitial every 3 completions
  static const _rewardedEveryN     = 10; // rewarded XP offer every 10

  // Telemetry counters (in-memory; wire to Firebase Analytics in production)
  int _interstitialsShown   = 0;
  int _rewardedShown        = 0;
  int _rewardedCompleted    = 0;
  int _bannerImpressions    = 0;

  // Read-only accessors for dashboards / debug overlays
  int get interstitialsShown  => _interstitialsShown;
  int get rewardedShown       => _rewardedShown;
  int get rewardedCompleted   => _rewardedCompleted;
  int get bannerImpressions   => _bannerImpressions;

  // ── Pro / ads gate ───────────────────────────────────────────────────────────
  /// False for Math IQ Pro subscribers — all ad surfaces should respect this.
  bool get adsEnabled => !SubscriptionService.instance.isPro;

  // ── Real AdMob full-screen ads ───────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;

  /// Whether a rewarded ad is loaded and ready to show.
  bool get isRewardedReady => _rewardedAd != null;

  /// Call once at app start (after MobileAds.initialize) to warm the cache.
  void init() {
    if (!adsEnabled) return;
    preloadInterstitial();
    preloadRewarded();
  }

  void preloadInterstitial() {
    if (!adsEnabled || _interstitialAd != null || _interstitialLoading) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (err) {
          _interstitialLoading = false;
          if (kDebugMode) print('[AdService] interstitial load failed: $err');
        },
      ),
    );
  }

  void preloadRewarded() {
    if (!adsEnabled || _rewardedAd != null || _rewardedLoading) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (err) {
          _rewardedLoading = false;
          if (kDebugMode) print('[AdService] rewarded load failed: $err');
        },
      ),
    );
  }

  /// Shows an interstitial when the frequency rules allow it.
  /// Returns true once the ad has been shown and dismissed.
  Future<bool> maybeShowInterstitial({
    AdPlacement placement = AdPlacement.levelInterstitial,
  }) async {
    if (!shouldShowInterstitial) {
      preloadInterstitial();
      return false;
    }
    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return false;
    }
    _interstitialAd = null;

    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadInterstitial();
        done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        if (kDebugMode) print('[AdService] interstitial show failed: $err');
        ad.dispose();
        preloadInterstitial();
        done.complete(false);
      },
    );
    _lastInterstitial   = DateTime.now();
    _sessionCompletions = 0;
    _interstitialsShown++;
    _log(placement, 'interstitial shown');
    await ad.show();
    return done.future;
  }

  /// Shows a rewarded ad. [onReward] fires only when the user watches enough
  /// to earn the reward. Returns true if the reward was granted.
  Future<bool> showRewarded({
    required VoidCallback onReward,
    AdPlacement placement = AdPlacement.levelFailedRewarded,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      preloadRewarded();
      return false;
    }
    _rewardedAd = null;

    var earned = false;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewarded();
        done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        if (kDebugMode) print('[AdService] rewarded show failed: $err');
        ad.dispose();
        preloadRewarded();
        done.complete(false);
      },
    );
    _rewardedShown++;
    _log(placement, 'rewarded shown');
    await ad.show(onUserEarnedReward: (_, reward) {
      earned = true;
      _rewardedCompleted++;
      _log(placement, 'rewarded completed');
      onReward();
    });
    return done.future;
  }

  // ── Lifecycle hooks ──────────────────────────────────────────────────────────
  void onLevelCompleted() {
    _sessionCompletions++;
    _totalCompletions++;
    // Every 10th completion: offer an opt-in rewarded ad (XP bonus).
    if (_totalCompletions % _rewardedEveryN == 0) _rewardedOfferPending = true;
  }

  /// True when the every-10-completions rewarded XP offer should be shown.
  /// The offer is opt-in (AdMob policy — rewarded ads can't be forced).
  bool get shouldOfferRewardedBonus =>
      adsEnabled && _rewardedOfferPending && isRewardedReady;

  /// Call after showing (or skipping) the milestone rewarded offer.
  void clearRewardedOffer() => _rewardedOfferPending = false;

  bool get shouldShowInterstitial {
    if (!adsEnabled) return false;
    if (_sessionCompletions < _interstitialEveryN) return false;
    if (_lastInterstitial != null &&
        DateTime.now().difference(_lastInterstitial!) < _interstitialGap) {
      return false;
    }
    return true;
  }

  void recordInterstitialShown() {
    _lastInterstitial   = DateTime.now();
    _sessionCompletions = 0;
    _interstitialsShown++;
    _log(AdPlacement.levelInterstitial, 'interstitial shown');
  }

  void recordRewardedShown()     { _rewardedShown++;     _log(AdPlacement.levelFailedRewarded, 'rewarded shown'); }
  void recordRewardedCompleted() { _rewardedCompleted++;  _log(AdPlacement.levelFailedRewarded, 'rewarded completed'); }
  void recordBannerImpression(AdPlacement p) { _bannerImpressions++;  _log(p, 'banner impression'); }

  void _log(AdPlacement p, String event) {
    if (kDebugMode) print('[AdService] ${p.name} → $event');
    AnalyticsService.instance.logAdEvent(
      placement: p.name,
      event: event,
    );
  }

  // ── Revenue estimation ───────────────────────────────────────────────────────
  /// Estimates daily ad revenue for a given daily-active-user count.
  /// Uses conservative industry averages for a kids / educational app.
  AdRevenueEstimate estimateRevenue(int dau) {
    // Average CPMs (USD) — educational category, India+Global blend
    const bannerCPM         = 0.70;   // $0.70
    const interstitialCPM   = 5.50;   // $5.50
    const rewardedCPM       = 13.00;  // $13.00

    // Impressions per user per day (conservative)
    const bannersPerUser        = 8.0;   // ~12 banner slots across all screens, ~8 seen per session
    const interstitialsPerUser  = 0.9;   // ~1 per session
    const rewardedPerUser       = 0.15;  // ~15% users watch one

    return AdRevenueEstimate(
      bannerDaily:       dau * bannersPerUser       * bannerCPM       / 1000,
      interstitialDaily: dau * interstitialsPerUser * interstitialCPM / 1000,
      rewardedDaily:     dau * rewardedPerUser      * rewardedCPM     / 1000,
    );
  }

  // ── Strategy manifest ────────────────────────────────────────────────────────
  static const List<AdSpec> strategy = [
    AdSpec(
      placement:   AdPlacement.homeBanner,
      type:        'Adaptive Banner',
      trigger:     'Always visible on Home screen',
      rationale:   'Highest dwell time — users browse before playing',
      expectedCPM: 0.70,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.levelSelectBanner,
      type:        'Adaptive Banner',
      trigger:     'Always visible on Level Select',
      rationale:   'High intent — user is deciding which level to play',
      expectedCPM: 0.70,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.levelInterstitial,
      type:        'Interstitial',
      trigger:     'Every 3 level completions, min 1-minute gap',
      rationale:   'Natural break point between levels; high viewability',
      expectedCPM: 5.50,
      size:        'Full screen',
    ),
    AdSpec(
      placement:   AdPlacement.levelFailedRewarded,
      type:        'Rewarded',
      trigger:     'User taps "Watch Ad → Free Retry" on failed level',
      rationale:   'User is motivated to retry; highest CPM format',
      expectedCPM: 13.00,
      size:        'Full screen video',
    ),
    AdSpec(
      placement:   AdPlacement.practiceInterstitial,
      type:        'Interstitial',
      trigger:     'Practice results, shares the every-3-completions cap',
      rationale:   'Natural break after a session; extends coverage to practice',
      expectedCPM: 5.50,
      size:        'Full screen',
    ),
    AdSpec(
      placement:   AdPlacement.challengeInterstitial,
      type:        'Interstitial',
      trigger:     'Challenge results, shares the every-3-completions cap',
      rationale:   'Post-survival cool-down; high viewability',
      expectedCPM: 5.50,
      size:        'Full screen',
    ),
    AdSpec(
      placement:   AdPlacement.challengeDoubleXpRewarded,
      type:        'Rewarded',
      trigger:     'User taps "Watch Ad → 2× XP" on challenge results',
      rationale:   'Opt-in value exchange; highest CPM format',
      expectedCPM: 13.00,
      size:        'Full screen video',
    ),
    AdSpec(
      placement:   AdPlacement.milestoneRewarded,
      type:        'Rewarded',
      trigger:     'Opt-in XP bonus offer every 10 completions',
      rationale:   'Celebratory moment; user primed to accept reward',
      expectedCPM: 13.00,
      size:        'Full screen video',
    ),
    AdSpec(
      placement:   AdPlacement.challengeResultsBanner,
      type:        'Adaptive Banner',
      trigger:     'Shown on Challenge Results screen',
      rationale:   'Post-game cool-down moment; relaxed viewing',
      expectedCPM: 0.70,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.practiceResultsBanner,
      type:        'Adaptive Banner',
      trigger:     'Shown on Practice Results screen',
      rationale:   'Inline between stats and action buttons',
      expectedCPM: 0.70,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.recordsBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer on Records screen',
      rationale:   'Low-competition slot; passive revenue',
      expectedCPM: 0.60,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.shellBanner,
      type:        'Adaptive Banner',
      trigger:     'Persistent above bottom nav in main shell',
      rationale:   'Highest total impressions — visible across all tab screens',
      expectedCPM: 0.70,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.achievementsBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer on Achievements screen',
      rationale:   'High-engagement screen; users review progress here',
      expectedCPM: 0.65,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.stickerBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer on Sticker Book screen',
      rationale:   'Collection browsing — relaxed, low-interruption viewing',
      expectedCPM: 0.60,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.dailyQuestsBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer on Daily Quests screen',
      rationale:   'Daily return driver — highest visit frequency',
      expectedCPM: 0.70,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.flagQuizBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer on Flag Quiz screen',
      rationale:   'Passive slot during quiz setup and review',
      expectedCPM: 0.65,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.levelPlayBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer during level gameplay',
      rationale:   'Non-intrusive; keeps revenue flowing during play',
      expectedCPM: 0.55,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.levelResultsBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer on Level Results screen',
      rationale:   'Post-level cool-down; user is reviewing their score',
      expectedCPM: 0.70,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.challengeBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer on Challenge screen',
      rationale:   'Passive slot during challenge setup',
      expectedCPM: 0.60,
      size:        'Full width × 52px',
    ),
    AdSpec(
      placement:   AdPlacement.reviewBanner,
      type:        'Adaptive Banner',
      trigger:     'Sticky footer on Wrong Answers Review screen',
      rationale:   'Users linger here — high dwell time',
      expectedCPM: 0.65,
      size:        'Full width × 52px',
    ),
  ];
}
