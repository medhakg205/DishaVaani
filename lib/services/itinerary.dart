import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'poi.dart';
import '../models/itinerary_stop.dart';
import 'device_identity.dart';
import 'secrets.dart';

class ItineraryService {
  static final CollectionReference _itinerariesRef = FirebaseFirestore.instance
      .collection('itineraries');

  // TEMPORARY: calling Gemini directly from the app, bypassing the Firebase
  // Functions backend entirely — that path is blocked on billing being
  // enabled on the project. This trades a small security downside (the
  // API key ships inside the app) for actually being able to build and
  // test the feature. Worth moving back to a real backend once billing
  // is sorted.
  static const String _geminiApiKey = geminiApiKey; // imported from secrets.dart, never committed

  /// Sends the uploaded file directly to Gemini and parses the structured
  /// stops out of the response.
  static Future<List<ItineraryStop>> parseItineraryFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => throw Exception('Unsupported file type: $extension'),
    };

    final fileBytes = await file.readAsBytes();

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
    );

    final prompt = TextPart(
      'Extract every planned visit from this travel itinerary. '
      'Return ONLY a JSON array, no other text, no markdown formatting. '
      'Each item must have exactly these fields: '
      '"placeName" (string), "date" (YYYY-MM-DD), '
      '"startTime" (HH:mm, 24-hour), "endTime" (HH:mm, 24-hour). '
      'If a specific time isn\'t given, make a reasonable estimate based on context. '
      'If a date isn\'t given, use today\'s date.',
    );

    final filePart = DataPart(mimeType, fileBytes);

    final response = await model.generateContent([
      Content.multi([prompt, filePart]),
    ]);

    var rawText = (response.text ?? '').trim();

    // Gemini sometimes wraps JSON in markdown code fences despite instructions.
    if (rawText.startsWith('```')) {
      rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    final stopsJson = jsonDecode(rawText) as List<dynamic>;

    return stopsJson
        .map((s) => ItineraryStop.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Saves parsed stops to Firestore, keyed by device — same pattern as
  /// SessionService.
  static Future<void> saveStops(List<ItineraryStop> stops) async {
    final deviceId = await DeviceIdentity.getId();

    await _itinerariesRef.doc(deviceId).set({
      'stops': stops.map((s) => s.toFirestore()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<ItineraryStop>> loadStops() async {
    final deviceId = await DeviceIdentity.getId();
    final doc = await _itinerariesRef.doc(deviceId).get();

    if (!doc.exists) return [];

    final data = doc.data() as Map<String, dynamic>;
    final stopsData = data['stops'] as List<dynamic>? ?? [];

    return stopsData
        .map((s) => ItineraryStop.fromFirestore(s as Map<String, dynamic>))
        .toList();
  }

  // Matches each parsed stop's plain-text place name against the real POI
  // database, filling in poiId/lat/long where a confident match is found.
  // Stops that can't be matched are kept as-is (unresolved), so the app can
  // still show them in a list, just without location-based inference working
  // for that specific stop.
  static Future<List<ItineraryStop>> resolveStops(
    List<ItineraryStop> stops,
  ) async {
    final poiService = PoiService();
    final resolved = <ItineraryStop>[];

    for (final stop in stops) {
      final matches = await poiService.searchPoisByName(stop.placeName);

      if (matches.isNotEmpty) {
        resolved.add(stop.copyWithMatch(matches.first));
      } else {
        resolved.add(stop); // no match found, keep unresolved
      }
    }

    return resolved;
  }
}