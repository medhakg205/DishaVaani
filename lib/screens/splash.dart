// splash.dart — screen 1: intro + location/compass permission request
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'home.dart';
import 'interest_quiz.dart';
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
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.maroon, width: 3),
                    ),
                    child: const Icon(
                      Icons.explore,
                      size: 80,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DISHAVAANI',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroon,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Point your phone. Listen in your language.\nNo QR codes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _openQuiz(context),
                      child: const Text('START PERSONALIZATION'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.maroon,
                        side: const BorderSide(color: AppColors.maroon),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      child: const Text('CHOOSE LANGUAGE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
