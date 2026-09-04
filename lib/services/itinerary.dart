import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'poi.dart';
import '../models/itinerary_stop.dart';
import 'device_identity.dart';

class ItineraryService {
  static final CollectionReference _itinerariesRef = FirebaseFirestore.instance
      .collection('itineraries');

  // TODO: point this at your actual backend once the parsing endpoint
  // exists — see note below about who builds this.
  static const String _parseEndpoint =
      'https://YOUR-BACKEND-URL/parse_itinerary';

  /// Sends the uploaded file to the backend, which uses Gemini to extract
  /// structured stops from it. Returns the parsed list, not yet saved.
  static Future<List<ItineraryStop>> parseItineraryFile(File file) async {
    final request = http.MultipartRequest('POST', Uri.parse(_parseEndpoint));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Backend returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final stopsJson = decoded['stops'] as List<dynamic>;

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
