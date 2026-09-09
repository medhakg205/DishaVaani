// theme_mode_toggle.dart — sleek animated switch between dark and light modes
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';

class ThemeModeToggle extends StatelessWidget {
  final bool isCompact;
  final bool showLabel;

  const ThemeModeToggle({
    super.key,
    this.isCompact = false,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        // When showLabel is true (landing page only), show Sun/Moon icon + text
        if (showLabel) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: AppSettings.toggleTheme,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF22161E).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFF5A623).withValues(alpha: 0.4)
                      : AppColors.maroon.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFFF5A623).withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      key: ValueKey(isDark),
                      size: 18,
                      color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDark ? 'Dark' : 'Light',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFFFFE082) : AppColors.maroon,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // On all other pages: ONLY Sun & Moon icon, NO text written!
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: AppSettings.toggleTheme,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: isCompact ? 38 : 42,
            height: isCompact ? 38 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF22161E).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFF5A623).withValues(alpha: 0.35)
                    : AppColors.maroon.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0xFFF5A623).withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  key: ValueKey(isDark),
                  size: isCompact ? 18 : 20,
                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
