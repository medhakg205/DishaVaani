import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/itinerary.dart';
import 'home.dart';

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
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _isUploading
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: maroon),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}