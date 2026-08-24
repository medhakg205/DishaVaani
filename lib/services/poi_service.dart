import 'package:cloud_firestore/cloud_firestore.dart';

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
}
