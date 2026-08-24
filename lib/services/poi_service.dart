import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import '../models/poi.dart';

class PoiService {
  final CollectionReference _poisRef = FirebaseFirestore.instance.collection(
    'pois',
  );

  // Fetches everything — kept for cases where you genuinely want all POIs
  Future<List<Poi>> fetchAllPois() async {
    final snapshot = await _poisRef.get();
    return snapshot.docs
        .map(
          (doc) =>
              Poi.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Fetches only POIs belonging to a specific monument
  Future<List<Poi>> fetchPoisByMonument(String monumentId) async {
    final pois = await fetchAllPois();
    final normalizedMonumentId = monumentId.trim().toLowerCase();

    return pois
        .where((poi) => poi.monumentId.toLowerCase() == normalizedMonumentId)
        .toList();
  }

  Stream<List<Poi>> watchPois() => _poisRef.snapshots().map(
    (snapshot) => snapshot.docs
        .map(
          (doc) =>
              Poi.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList(),
  );

  Future<String?> uploadAudio({
    required PlatformFile file,
    required String monumentId,
  }) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('The selected audio file could not be read.');
    }
    final safeMonument = monumentId.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final reference = FirebaseStorage.instance.ref(
      'poi_audio/$safeMonument/${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );
    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: file.extension == 'mp3' ? 'audio/mpeg' : null,
      ),
    );
    return reference.getDownloadURL();
  }

  Future<void> savePoi({String? id, required Map<String, dynamic> data}) async {
    final payload = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      await _poisRef.add(payload);
    } else {
      await _poisRef.doc(id).set({
        ...payload,
        'scriptTextHindi': FieldValue.delete(),
        'createdAt': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> deletePoi(Poi poi) async {
    await _poisRef.doc(poi.id).delete();
  }
}
