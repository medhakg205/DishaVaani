// app.dart — MaterialApp root: reactive theme mode + initial route
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/settings/app_settings.dart';
import 'screens/splash.dart';

class DishaVaaniApp extends StatelessWidget {
  const DishaVaaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DishaVaani',
          themeMode: themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Georgia',
            scaffoldBackgroundColor: AppColors.lightBgMid,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.maroon,
              brightness: Brightness.light,
              surface: AppColors.lightSurface,
              primary: AppColors.maroon,
              secondary: AppColors.terracotta,
            ),
            cardTheme: CardThemeData(
              color: AppColors.lightSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.lightBorder),
              ),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Georgia',
            scaffoldBackgroundColor: AppColors.darkBgBottom,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.crimsonAction,
              brightness: Brightness.dark,
              surface: AppColors.darkSurface,
              primary: AppColors.crimsonAction,
              secondary: AppColors.copperGlow,
            ),
            cardTheme: CardThemeData(
              color: AppColors.darkSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.darkBorder),
              ),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
