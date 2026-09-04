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

  // Add this method inside the existing PoiService class

// Searches ALL POIs by name, not just nearby ones — itinerary stops can be
// anywhere, not just where the user currently is.
  Future<List<Poi>> searchPoisByName(String query) async {
    if (query.trim().isEmpty) return [];
    final allPois = await fetchAllPois();
    final lowerQuery = query.trim().toLowerCase();
    return allPois
        .where((poi) => poi.name.toLowerCase().contains(lowerQuery))
        .take(5)
        .toList();

  }

}
