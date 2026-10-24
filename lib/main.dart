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
    return MaterialApp(
      title: 'Math IQ',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AnalyticsService.instance.observer],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.creamBg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceContainerLowest,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.onSurface,
          onError: Colors.white,
        ),
        fontFamily: 'BeVietnamPro',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'BeVietnamPro',
            color: AppColors.onSurface,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(
                color: AppColors.surfaceContainerHighest, width: 2),
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
  }
}
