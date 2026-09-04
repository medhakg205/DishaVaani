// app.dart — MaterialApp root: theme + initial route
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'screens/splash_screen.dart';

class DishaVaaniApp extends StatelessWidget {
  const DishaVaaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DishaVaani',
      theme: ThemeData(
        fontFamily: 'Georgia',
        scaffoldBackgroundColor: AppColors.sandstone,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.maroon),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}