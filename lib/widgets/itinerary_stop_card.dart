import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../models/itinerary_stop.dart';

class ItineraryStopCard extends StatelessWidget {
  final ItineraryStop stop;
  final int stopIndex;
  final VoidCallback onSkip;
  final VoidCallback onFinishEarly;
  final VoidCallback onRequestDetour;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isAvailable;

  const ItineraryStopCard({
    super.key,
    required this.stop,
    required this.stopIndex,
    required this.onSkip,
    required this.onFinishEarly,
    required this.onRequestDetour,
    this.onTap,
    this.isSelected = false,
    this.isAvailable = true,
  });

  String? _resolveMonumentAsset(String? monumentId, String placeName) {
    final lowerName = placeName.toLowerCase();
    final lowerId = (monumentId ?? '').toLowerCase();

    if (lowerId.contains('qutub') || lowerName.contains('qutub')) {
      return 'assets/images/qutub_minar_tower.jpg';
    } else if (lowerId.contains('red_fort') || lowerName.contains('red fort')) {
      return 'assets/images/red_fort_lahori_gate.jpg';
    } else if (lowerId.contains('humayun') || lowerName.contains('humayun')) {
      return 'assets/images/humayuns_tomb.jpg';
    } else if (lowerId.contains('india_gate') || lowerName.contains('india gate')) {
      return 'assets/images/india_gate.jpg';
    } else if (lowerId.contains('agrasen') || lowerName.contains('agrasen') || lowerName.contains('baoli')) {
      return 'assets/images/agrasen_ki_baoli.jpg';
    } else if (lowerId.contains('jama') || lowerName.contains('jama')) {
      return 'assets/images/jama_masjid.jpg';
    } else if (lowerId.contains('haveli') || lowerName.contains('haveli') || lowerName.contains('dharampura')) {
      return 'assets/images/jama_masjid.jpg';
    } else if (lowerId.contains('neemrana') || lowerName.contains('neemrana')) {
      return 'assets/images/agrasen_ki_baoli.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, _, child) {
        final isDark = AppSettings.isDarkMode;
        final assetPath = _resolveMonumentAsset(stop.monumentId, stop.placeName);

        // Theme colors
        final cardBg = isDark
            ? (isSelected ? const Color(0xFF2E1F26) : const Color(0xFF221A20))
            : (isSelected ? const Color(0xFFFFF9F5) : Colors.white);

        final borderColor = isSelected
            ? (isDark ? AppColors.copperGlow : AppColors.maroon)
            : (isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder);

        final primaryTextColor = isDark ? Colors.white : AppColors.lightTextPrimary;
        final secondaryTextColor = isDark ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: (isDark ? AppColors.copperGlow : AppColors.maroon).withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Thumbnail + Details + Selected Pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Monument Image or Icon Avatar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF38252C) : AppColors.sandstone,
                            ),
                            child: assetPath != null
                                ? Image.asset(
                                    assetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => _buildFallbackAvatar(isDark),
                                  )
                                : _buildFallbackAvatar(isDark),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title, Time, & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      stop.placeName,
                                      style: TextStyle(
                                        fontFamily: 'serif',
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isDark ? AppColors.copperGlow : AppColors.maroon).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: (isDark ? AppColors.copperGlow : AppColors.maroon).withOpacity(0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'TARGET',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Time pill & guide readiness
                              Row(
                                children: [
                                  if (stop.startTime.isNotEmpty && stop.endTime.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.06)
                                            : Colors.black.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 11,
                                            color: secondaryTextColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${stop.startTime} - ${stop.endTime}',
                                            style: TextStyle(
                                              color: secondaryTextColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  if (isAvailable)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.headphones_rounded,
                                          size: 12,
                                          color: Color(0xFF4CAF50),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Guide ready',
                                          style: TextStyle(
                                            color: const Color(0xFF4CAF50),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Guide in prep',
                                      style: TextStyle(
                                        color: isDark ? Colors.white38 : Colors.black38,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                    ),
                    const SizedBox(height: 8),

                    // Bottom Action Row: Skip, Finish Early, Detour (Unified Palette)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Skip Pill Button
                        InkWell(
                          onTap: onSkip,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.copperGlow.withOpacity(0.08)
                                  : AppColors.terracotta.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.copperGlow.withOpacity(0.25)
                                    : AppColors.terracotta.withOpacity(0.22),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.skip_next_rounded,
                                  size: 14,
                                  color: isDark ? AppColors.copperGlow : AppColors.terracotta,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Finish Early Pill Button
                        InkWell(
                          onTap: onFinishEarly,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.copperGlow.withOpacity(0.08)
                                  : AppColors.terracotta.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.copperGlow.withOpacity(0.25)
                                    : AppColors.terracotta.withOpacity(0.22),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: isDark ? AppColors.copperGlow : AppColors.terracotta,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Finish Early',
                                  style: TextStyle(
                                    color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Detour Pill Button
                        InkWell(
                          onTap: onRequestDetour,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.copperGlow.withOpacity(0.08)
                                  : AppColors.terracotta.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.copperGlow.withOpacity(0.25)
                                    : AppColors.terracotta.withOpacity(0.22),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.explore_outlined,
                                  size: 14,
                                  color: isDark ? AppColors.copperGlow : AppColors.terracotta,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Detour',
                                  style: TextStyle(
                                    color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackAvatar(bool isDark) {
    return Center(
      child: Icon(
        Icons.account_balance_rounded,
        size: 26,
        color: isDark ? AppColors.copperGlow : AppColors.maroon,
      ),
    );
  }
}