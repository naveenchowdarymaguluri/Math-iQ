import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Full-width AdMob adaptive banner.
/// • Returns SizedBox.shrink() for Math IQ Pro subscribers.
/// • Shows a 52-dp placeholder while the ad loads.
/// • Uses production IDs in release, Google test IDs in debug.
///
/// iOS setup required before ship:
///   Add to ios/Runner/Info.plist:
/// ```xml
///   <key>GADApplicationIdentifier</key>
///   <string>YOUR-IOS-ADMOB-APP-ID</string>
/// ```
class AdBanner extends StatefulWidget {
  final String? placement;
  const AdBanner({super.key, this.placement});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (AdService.instance.adsEnabled) {
      _loadAd();
    } else {
      _failed = true;
    }
  }

  void _loadAd() {
    _ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _loaded = true;
            _failed = false;
          });
          AdService.instance.recordBannerImpression(
            _toPlacement(widget.placement),
          );
        },
        onAdFailedToLoad: (ad, err) {
          if (kDebugMode) {
            debugPrint('[AdBanner] ${widget.placement}: $err');
          }
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
              _failed = true;
            });
          }
        },
      ),
    )..load();
  }

  AdPlacement _toPlacement(String? p) => switch (p) {
        'homeBanner'             => AdPlacement.homeBanner,
        'levelSelectBanner'      => AdPlacement.levelSelectBanner,
        'practiceResultsBanner'  => AdPlacement.practiceResultsBanner,
        'challengeResultsBanner' => AdPlacement.challengeResultsBanner,
        'recordsBanner'          => AdPlacement.recordsBanner,
        'achievementsBanner'     => AdPlacement.achievementsBanner,
        'stickerBanner'          => AdPlacement.stickerBanner,
        'dailyQuestsBanner'      => AdPlacement.dailyQuestsBanner,
        'flagQuizBanner'         => AdPlacement.flagQuizBanner,
        'reviewBanner'           => AdPlacement.reviewBanner,
        'levelPlayBanner'        => AdPlacement.levelPlayBanner,
        'levelResultsBanner'     => AdPlacement.levelResultsBanner,
        'challengeBanner'        => AdPlacement.challengeBanner,
        'shellBanner'            => AdPlacement.shellBanner,
        'practiceGameplay'       => AdPlacement.practiceGameplay,
        _                        => AdPlacement.homeBanner,
      };

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pro subscribers or failed ads see no empty space
    if (!AdService.instance.adsEnabled || _failed) return const SizedBox.shrink();

    if (!_loaded || _ad == null) {
      // Placeholder keeps layout stable while ad loads
      return const SizedBox(height: 52);
    }

    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
