// splash_screen.dart — screen 1: intro + location/compass permission request
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/app_colors.dart';
import 'home_screen.dart';
import 'language_select_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isRequestingPermission = false;

  Future<void> _requestPermissionsAndContinue(BuildContext context) async {
    setState(() => _isRequestingPermission = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;
    setState(() => _isRequestingPermission = false);

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required to use DishaVaani.')),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.maroon, width: 3)),
                child: const Icon(Icons.explore, size: 80, color: AppColors.terracotta),
              ),
              const SizedBox(height: 24),
              const Text(
                'DISHAVAANI',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.maroon, letterSpacing: 3),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isRequestingPermission ? null : () => _requestPermissionsAndContinue(context),
                  child: _isRequestingPermission
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('ALLOW LOCATION + COMPASS'),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectScreen()));
                  },
                  child: const Text('CHOOSE LANGUAGE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}