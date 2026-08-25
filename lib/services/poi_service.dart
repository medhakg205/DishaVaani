import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/poi.dart';

class PoiService {
  final CollectionReference _poisRef = FirebaseFirestore.instance.collection(
    'pois',
  );

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // FETCH ALL POIs
  // ============================================================

  Future<List<Poi>> fetchAllPois() async {
    final snapshot = await _poisRef.get();

    return snapshot.docs
        .map(
          (doc) =>
              Poi.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // ============================================================
  // FETCH POIs FOR ONE MONUMENT
  // ============================================================

  Future<List<Poi>> fetchPoisByMonument(String monumentId) async {
    final pois = await fetchAllPois();

    final normalizedMonumentId = Poi.normalizeMonumentId(monumentId);

    return pois.where((poi) {
      return Poi.normalizeMonumentId(poi.monumentId) == normalizedMonumentId;
    }).toList();
  }

  // ============================================================
  // REAL-TIME FIRESTORE LISTENER
  // ============================================================

  Stream<List<Poi>> watchPois() {
    return _poisRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                Poi.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // ============================================================
  // UPLOAD AUDIO TO SUPABASE
  // ============================================================

  Future<String?> uploadAudio({
    required PlatformFile file,
    required String monumentId,
  }) async {
    final bytes = file.bytes;

    if (bytes == null) {
      throw StateError('The selected audio file could not be read.');
    }

    // Make a safe folder name.
    final safeMonument = monumentId.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    // Make a safe filename.
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final filePath = '$safeMonument/${timestamp}_$safeName';

    // Determine audio MIME type.
    final contentType = _getAudioContentType(file.extension);

    // Upload to the PUBLIC Supabase bucket.
    await _supabase.storage
        .from('audio')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    // Generate the public URL.
    final publicUrl = _supabase.storage.from('audio').getPublicUrl(filePath);

    return publicUrl;
  }

  // ============================================================
  // AUDIO MIME TYPE
  // ============================================================

  String _getAudioContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'mp3':
        return 'audio/mpeg';

      case 'wav':
        return 'audio/wav';

      case 'm4a':
        return 'audio/mp4';

      case 'aac':
        return 'audio/aac';

      case 'ogg':
        return 'audio/ogg';

      case 'flac':
        return 'audio/flac';

      default:
        return 'application/octet-stream';
    }
  }

  // ============================================================
  // SAVE / UPDATE POI
  // ============================================================

  Future<void> savePoi({String? id, required Map<String, dynamic> data}) async {
    /*
      IMPORTANT:

      Your Firestore schema is:

      audioUrls
        en: "..."

      scripts
        en: "..."

      bearingTolerance
      lat
      long
      monumentId
      name

      The AdminDashboard currently sends:

      scriptText
      audioUrl

      So this method converts those UI names into
      your ACTUAL Firestore schema.
    */

    final String monumentId = Poi.normalizeMonumentId(
      (data['monumentId'] ?? '').toString(),
    );

    final String name = (data['name'] ?? '').toString().trim();

    final String scriptText = (data['scriptText'] ?? '').toString().trim();

    final String audioUrl = (data['audioUrl'] ?? '').toString().trim();

    final double lat = (data['lat'] as num).toDouble();

    final double long = (data['long'] as num).toDouble();

    // Kept at a default for the mobile matching engine; it is no longer an
    // admin-facing control.
    const double bearingTolerance = 20;

    final payload = <String, dynamic>{
      'monumentId': monumentId,
      'name': name,
      'lat': lat,
      'long': long,

      // YOUR EXISTING SCHEMA
      'scripts': {'en': scriptText},

      // YOUR EXISTING SCHEMA
      'audioUrls': {'en': audioUrl},

      // YOUR EXISTING SCHEMA
      'bearingTolerance': bearingTolerance,

      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ----------------------------------------------------------
    // CREATE
    // ----------------------------------------------------------

    if (id == null) {
      await _poisRef.add(payload);
      return;
    }

    // ----------------------------------------------------------
    // UPDATE
    // ----------------------------------------------------------

    await _poisRef.doc(id).set({
      ...payload,
      'createdAt': FieldValue.delete(),
      'compassHeading': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  // ============================================================
  // DELETE POI
  // ============================================================

  Future<void> deletePoi(Poi poi) async {
    await _poisRef.doc(poi.id).delete();
  }
}
