import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme/app_colors.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_shell.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/player_data_service.dart';
import 'services/level_service.dart';
import 'services/sound_service.dart';
import 'services/subscription_service.dart';
import 'models/app_theme_custom.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Google Mobile Ads ─────────────────────────────────────────────────────
  // Initialize before Firebase so the first ad request can go out immediately.
  // NOTE (iOS): add GADApplicationIdentifier to ios/Runner/Info.plist before ship.
  try {
    await MobileAds.instance.initialize();
    // Warm the interstitial / rewarded cache so the first show is instant.
    AdService.instance.init();
  } catch (e) {
    // Non-fatal — app works without ads (e.g. iOS simulator without Info.plist key)
    debugPrint('[AdMob] init failed: $e');
  }

  // ── Firebase ───────────────────────────────────────────────────────────────
  await Firebase.initializeApp();

  // Route Flutter framework errors → Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Route Dart async errors → Crashlytics
  // (wraps runApp so all uncaught errors are captured)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Load persistent player data
  await PlayerDataService.instance.load();

  // Load level progress
  await LevelService.instance.load();

  // Pre-generate WAV sound effects
  SoundService.instance.init();

  // Initialize RevenueCat — must run after Firebase so Crashlytics catches errors
  await SubscriptionService.instance.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MathIQApp());
}

class MathIQApp extends StatelessWidget {
  const MathIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerDataService.instance,
      builder: (context, _) {
        final customTheme = AppThemeCustom.getById(
            PlayerDataService.instance.equippedThemeId);
        final isDark = customTheme.background.computeLuminance() < 0.2;

        return MaterialApp(
          title: 'Math IQ',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [AnalyticsService.instance.observer],
          theme: ThemeData(
            useMaterial3: true,
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: customTheme.background,
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: customTheme.primary,
              secondary: customTheme.accent,
              surface: customTheme.surface,
              error: AppColors.error,
              onPrimary: isDark ? Colors.black : Colors.white,
              onSecondary: isDark ? Colors.black : Colors.white,
              onSurface: customTheme.onBackground,
              onError: Colors.white,
            ),
            fontFamily: 'BeVietnamPro',
            textTheme: TextTheme(
              bodyMedium: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: customTheme.onBackground,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: customTheme.surface,
              foregroundColor: customTheme.onBackground,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: customTheme.primary,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: customTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                    color: customTheme.surfaceContainer, width: 2),
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          home: PlayerDataService.instance.hasSeenOnboarding
              ? const MainShell()
              : const WelcomeScreen(),
        );
      },
    );
  }
}
