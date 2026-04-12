import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart' as sys;

import 'core/constants/app_colors.dart';
import 'screens/home_screen.dart';
import 'providers/storage_provider.dart';
import 'providers/audio_provider.dart';
import 'services/audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final audioHandler = await sys.AudioService.init<AppAudioHandler>(
    builder: () => AppAudioHandler(),
    config: const sys.AudioServiceConfig(
      androidNotificationChannelId: 'com.prepmantra.audio',
      androidNotificationChannelName: 'PrepMantra Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appAudioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PrepMantra Audio',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.onBackground,
          onError: Colors.white,
        ),
        cardTheme: const CardTheme(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.onBackground,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.onSurface,
          textColor: AppColors.onBackground,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 0,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.onBackground),
          bodyMedium: TextStyle(color: AppColors.onSurface),
          titleMedium: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.onSurface),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.surfaceVariant,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.surfaceVariant,
          contentTextStyle: TextStyle(color: AppColors.onBackground),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
