// poi.dart — Firestore reads for POIs
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/poi.dart';

class PoiService {
  final CollectionReference _poisRef = FirebaseFirestore.instance.collection(
    'pois',
  );

  Future<List<Poi>> fetchAllPois() async {
    final snapshot = await _poisRef.get();
    return snapshot.docs
        .map(
          (doc) =>
              Poi.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

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
  // Searches the monuments collection by display name (e.g. "Qutub Minar"),
// converting each monument's snake_case document ID the same way Home
// screen does, since monuments don't store a separate display-name field.
Future<Map<String, dynamic>?> findMonumentByName(String query) async {
  final snapshot = await FirebaseFirestore.instance.collection('monuments').get();
  final lowerQuery = query.trim().toLowerCase();

  for (final doc in snapshot.docs) {
    final displayName = doc.id
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    if (displayName.toLowerCase() == lowerQuery) {
      final data = doc.data();
      return {
        'monumentId': doc.id,
        'lat': data['lat'],
        'long': data['long'],
      };
    }
  }
  return null;
}
}
