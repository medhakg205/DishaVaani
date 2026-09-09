// language_select.dart — narration language picker
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../widgets/theme_mode_toggle.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late String selectedLanguageCode;

  final List<Map<String, String>> languages = const [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ'},
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguageCode = AppSettings.selectedLanguage;
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
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white70 : AppColors.maroon,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Choose Language',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              fontFamily: 'Georgia',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const ThemeModeToggle(),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select your preferred narration language',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.separated(
                              itemCount: languages.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final lang = languages[index];
                                final bool isSelected = selectedLanguageCode == lang['code'];

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() => selectedLanguageCode = lang['code']!),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isDark
                                                ? AppColors.copperGlow.withOpacity(0.12)
                                                : const Color(0xFFFFF0E6))
                                            : (isDark
                                                ? AppColors.darkSurface.withOpacity(0.7)
                                                : Colors.white),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? (isDark ? AppColors.copperGlow : AppColors.terracotta)
                                              : (isDark
                                                  ? Colors.white.withOpacity(0.08)
                                                  : AppColors.lightBorder),
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lang['name']!,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    fontFamily: 'Georgia',
                                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  lang['native']!,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: isDark ? AppColors.copperGlow : AppColors.terracotta,
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                  color: (isDark ? AppColors.crimsonAction : AppColors.maroon)
                                      .withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
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
                              onPressed: () {
                                AppSettings.selectedLanguage = selectedLanguageCode;
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'CONFIRM LANGUAGE',
                                style: TextStyle(
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
