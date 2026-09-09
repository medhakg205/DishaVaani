// splash.dart — screen 1: intro + location/compass permission request
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../widgets/theme_mode_toggle.dart';
import 'interest_quiz.dart';
import 'itinerary_import.dart';
import 'language_select.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _openQuiz(BuildContext context) async {
    final completedQuiz = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const InterestQuizScreen()),
    );

    if (!context.mounted || completedQuiz != true) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ItineraryImportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, _, child) {
        final isDark = AppSettings.isDarkMode;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.darkBgTop,
                        AppColors.darkBgMid,
                        AppColors.darkBgBottom,
                      ]
                    : [
                        AppColors.lightBgTop,
                        AppColors.lightBgMid,
                        AppColors.lightBgBottom,
                      ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Main Content
                  LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),

                            // Glowing Central Emblem
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.copperGlow.withOpacity(0.2),
                                          Colors.transparent,
                                        ]
                                      : [
                                          AppColors.terracotta.withOpacity(0.12),
                                          Colors.transparent,
                                        ],
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.copperGlow.withOpacity(0.6)
                                      : AppColors.terracotta.withOpacity(0.7),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? AppColors.copperGlow.withOpacity(0.25)
                                        : AppColors.terracotta.withOpacity(0.15),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.explore_rounded,
                                size: 76,
                                color: isDark ? AppColors.copperGlow : AppColors.terracotta,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // App Name
                            Text(
                              'DISHAVAANI',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Georgia',
                                color: isDark ? Colors.white : AppColors.maroon,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Subtitle
                            Text(
                              'Point your phone. Listen in your language.\nAI-driven heritage tours.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Start Personalization Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.crimsonAction,
                                          const Color(0xFF6B1D2F),
                                        ]
                                      : [
                                          AppColors.maroon,
                                          const Color(0xFF8B3A4C),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark
                                            ? AppColors.crimsonAction
                                            : AppColors.maroon)
                                        .withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _openQuiz(context),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'START PERSONALIZATION',
                                      style: TextStyle(
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Choose Language Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? AppColors.copperGlow : AppColors.maroon,
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.copperGlow.withOpacity(0.5)
                                        : AppColors.maroon.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LanguageSelectScreen(),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.translate_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'CHOOSE LANGUAGE',
                                      style: TextStyle(
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Right Theme Switcher (rendered above scroll view so it's always clickable)
                  const Positioned(
                    top: 14,
                    right: 16,
                    child: ThemeModeToggle(showLabel: true),
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