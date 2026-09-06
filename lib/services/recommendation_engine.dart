import 'dart:math';
import '../models/monument.dart';
import '../models/interest_profile.dart';
import 'matching_engine.dart'; // Provides haversineDistance

class RecommendationResult {
  final Monument monument;
  final double score;
  final double distanceMeters;
  final double interestScore;

  RecommendationResult({
    required this.monument,
    required this.score,
    required this.distanceMeters,
    required this.interestScore,
  });
}

class RecommendationEngine {
  static const double interestWeight = 0.6;
  static const double proximityWeight = 0.4;
  static const double defaultMaxRadiusMeters = 3000.0; // 3 km default search radius

  /// Ranks candidate monuments based on interest match and physical distance.
  static List<RecommendationResult> rank({
    required List<Monument> candidates,
    required InterestProfile profile,
    required double currentLat,
    required double currentLon,
    String? excludeMonumentId,
    double maxRadiusMeters = defaultMaxRadiusMeters,
    int maxResults = 5,
  }) {
    final profileMap = profile.toJson();
    final results = <RecommendationResult>[];

    for (final monument in candidates) {
      if (monument.id == excludeMonumentId) continue;

      // Use haversineDistance from matching_engine.dart
      final distance = haversineDistance(
        currentLat,
        currentLon,
        monument.lat,
        monument.long,
      );

      if (distance > maxRadiusMeters) continue;

      final interestScore = _interestMatchScore(monument.categories, profileMap);
      final proximityScore = _proximityScore(distance, maxRadiusMeters);
      final combined = (interestWeight * interestScore) + (proximityWeight * proximityScore);

      results.add(RecommendationResult(
        monument: monument,
        score: combined,
        distanceMeters: distance,
        interestScore: interestScore,
      ));
    }

    // Sort descending by combined score
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(maxResults).toList();
  }

  /// Averages interest values across categories to prevent multi-tag score inflation
  static double _interestMatchScore(List<String> categories, Map<String, dynamic> profile) {
    if (categories.isEmpty) return 0.0;
    double sum = 0.0;
    for (final cat in categories) {
      final val = profile[cat];
      if (val is num) {
        sum += val.toDouble();
      }
    }
    return sum / categories.length;
  }

  /// Exponential decay score between 1.0 (at 0m) down toward 0.0 (near maxRadius)
  static double _proximityScore(double distanceMeters, double maxRadius) {
    if (maxRadius <= 0) return 0.0;
    return exp(-distanceMeters / (maxRadius / 3));
  }
}