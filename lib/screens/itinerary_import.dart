import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../core/constants/app_colors.dart';
import '../core/settings/app_settings.dart';
import '../services/itinerary.dart';
import '../widgets/theme_mode_toggle.dart';
import 'home.dart';

class ItineraryImportScreen extends StatefulWidget {
  const ItineraryImportScreen({super.key});

  @override
  State<ItineraryImportScreen> createState() => _ItineraryImportScreenState();
}

class _ItineraryImportScreenState extends State<ItineraryImportScreen> {
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickAndUploadItinerary() async {
    setState(() => _errorMessage = null);

    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (files.isEmpty) return; // user cancelled

    final pickedFile = files.first;

    Uint8List bytes;
    try {
      // file_picker v12 dropped the always-loaded `.bytes` property —
      // you now have to explicitly ask it to load the content.
      bytes = await pickedFile.readAsBytes();
    } catch (e) {
      setState(() => _errorMessage = 'Could not read that file. Try picking it again.');
      return;
    }

    final fileSizeInMB = bytes.length / (1024 * 1024);
    if (fileSizeInMB > 20) {
      setState(() => _errorMessage = 'That file is too large. Try a smaller photo or PDF (under 20MB).');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final parsedStops = await ItineraryService.parseItineraryBytes(
        bytes,
        extension: pickedFile.extension ?? '',
      );
      if (!mounted) return;

      final resolvedStops = await ItineraryService.resolveStops(parsedStops);
      if (!mounted) return;

      await ItineraryService.saveStops(resolvedStops);
      if (!mounted) return;

      final unresolvedCount = resolvedStops
          .where((s) => s.monumentId == null)
          .length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unresolvedCount == 0
                ? 'Imported ${resolvedStops.length} stop${resolvedStops.length == 1 ? '' : 's'}.'
                : 'Imported ${resolvedStops.length} stops — $unresolvedCount could not be matched.',
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(itineraryStops: resolvedStops),
        ),
      );
    } catch (e) {
      // TEMPORARY — showing the real error while debugging. Revert to the
      // friendly message once this is working.
      setState(() => _errorMessage = 'DEBUG: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
                            'Import Itinerary',
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),

                          // Generate Itinerary (Coming Soon)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.copperGlow.withOpacity(0.15)
                                        : AppColors.terracotta.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: isDark ? AppColors.copperGlow : AppColors.maroon,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Itinerary Generator',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white70 : AppColors.maroon,
                                          fontSize: 16,
                                          fontFamily: 'Georgia',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Coming soon — build a tailored plan from scratch',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white38 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Upload File Card
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isUploading ? null : _pickAndUploadItinerary,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFF2C1924),
                                            const Color(0xFF20131B),
                                          ]
                                        : [
                                            Colors.white,
                                            const Color(0xFFFDF7F2),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.copperGlow.withOpacity(0.4)
                                        : AppColors.terracotta.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? AppColors.copperGlow.withOpacity(0.1)
                                          : AppColors.terracotta.withOpacity(0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.crimsonAction.withOpacity(0.3)
                                            : AppColors.terracotta.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: _isUploading
                                          ? SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: isDark
                                                    ? AppColors.copperGlow
                                                    : AppColors.terracotta,
                                              ),
                                            )
                                          : Icon(
                                              Icons.upload_file_rounded,
                                              color: isDark
                                                  ? AppColors.copperGlow
                                                  : AppColors.terracotta,
                                              size: 26,
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isUploading
                                                ? 'Parsing Itinerary...'
                                                : 'Upload Itinerary Document',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppColors.maroon,
                                              fontSize: 16,
                                              fontFamily: 'Georgia',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Photo, PNG, or PDF — parsed automatically with AI',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white54 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],

                          const Spacer(),

                          // Skip button
                          Center(
                            child: TextButton(
                              onPressed: _isUploading
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const HomeScreen(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Skip for now →',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.copperGlow
                                      : AppColors.maroon,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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