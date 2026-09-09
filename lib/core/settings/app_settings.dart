// app_settings.dart — global settings (selected language, theme, interest profile) + language code map
import 'package:flutter/material.dart';

class AppSettings {
  static String selectedLanguage = 'en';
  static Map<String, double> interestProfile = {};

  // Global Theme Mode state: default to dark mode
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static void toggleTheme() {
    themeModeNotifier.value =
        isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }
}

const Map<String, String> languageCodes = {
  'English': 'en',
  'Hindi': 'hi',
  'Tamil': 'ta',
  'Telugu': 'te',
  'Kannada': 'kn',
  'Malayalam': 'ml',
  'Marathi': 'mr',
  'Bengali': 'bn',
  'Gujarati': 'gu',
  'Punjabi': 'pa',
};
