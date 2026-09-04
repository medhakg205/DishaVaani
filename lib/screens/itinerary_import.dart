import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/itinerary.dart';

const Color maroon = Color(0xFF6B2737);
const Color terracotta = Color(0xFFC1652F);
const Color sandstone = Color(0xFFF5EFE6);

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

    if (files.isEmpty || files.first.path == null) return;

    final file = File(files.first.path!);
    setState(() => _isUploading = true);

    try {
      final parsedStops = await ItineraryService.parseItineraryFile(file);
      if (!mounted) return;

      final resolvedStops = await ItineraryService.resolveStops(parsedStops);
      if (!mounted) return;

      await ItineraryService.saveStops(resolvedStops);
      if (!mounted) return;

      final unresolvedCount = resolvedStops
          .where((s) => s.poiId == null)
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
      Navigator.pop(context);
    } catch (e) {
      setState(
        () => _errorMessage =
            'Could not read that itinerary. Try a clearer photo or PDF.',
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandstone,
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Import itinerary',
          style: TextStyle(color: Colors.white, fontFamily: 'Georgia'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.5,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: maroon, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Generate itinerary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: maroon,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Coming soon — build a plan from scratch',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _isUploading ? null : _pickAndUploadItinerary,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: terracotta, width: 1.5),
                ),
                child: Row(
                  children: [
                    _isUploading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: terracotta,
                            ),
                          )
                        : const Icon(
                            Icons.upload_file,
                            color: terracotta,
                            size: 28,
                          ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isUploading
                                ? 'Reading your itinerary...'
                                : 'Upload itinerary',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: maroon,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Photo or PDF, read automatically',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
