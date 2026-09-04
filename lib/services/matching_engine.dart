// matching_engine.dart — distance/bearing math + POI candidate matching & ranking
import 'dart:math';

import '../models/poi.dart';

// TODO: demo detection radius — restore to your real on-site range (~5–15m) before shipping
const double kMinDetectionRadiusMeters = 0;
const double kMaxDetectionRadiusMeters = 100;
const double kDefaultBearingToleranceDegrees = 25;

class MatchResult {
  final Poi? singleMatch;
  final List<Poi> queue;
  final bool hasMatch;

  MatchResult({this.singleMatch, this.queue = const []})
      : hasMatch = singleMatch != null || queue.isNotEmpty;
}

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000;
  double toRadians(double degree) => degree * pi / 180;

  final double dLat = toRadians(lat2 - lat1);
  final double dLon = toRadians(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRadians(lat1)) * cos(toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
  double toRadians(double degree) => degree * pi / 180;
  double toDegrees(double radian) => radian * 180 / pi;

  final double dLon = toRadians(lon2 - lon1);
  final double lat1Rad = toRadians(lat1);
  final double lat2Rad = toRadians(lat2);

  final double y = sin(dLon) * cos(lat2Rad);
  final double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

  return (toDegrees(atan2(y, x)) + 360) % 360;
}

double bearingDifference(double heading, double bearing) {
  double difference = (bearing - heading).abs();
  if (difference > 180) difference = 360 - difference;
  return difference;
}

bool isWithinToleranceCone(double heading, double bearing, {double tolerance = kDefaultBearingToleranceDegrees}) {
  return bearingDifference(heading, bearing) <= tolerance;
}

List<Poi> findCandidatePOIs(
  double userLat,
  double userLon,
  double userHeading,
  List<Poi> allPOIs, {
  bool debugLogging = false, // was an unconditional print() before — gated now, was spamming console every reading
}) {
  final List<Poi> candidates = [];

  for (final Poi poi in allPOIs) {
    final double distance = haversineDistance(userLat, userLon, poi.lat, poi.long);
    final double bearing = calculateBearing(userLat, userLon, poi.lat, poi.long);
    final double tolerance = poi.bearingTolerance > 0 ? poi.bearingTolerance : kDefaultBearingToleranceDegrees;
    final double angleDifference = bearingDifference(userHeading, bearing);

    final bool inRange = distance >= kMinDetectionRadiusMeters && distance <= kMaxDetectionRadiusMeters;
    final bool facingIt = angleDifference <= tolerance;

    if (debugLogging) {
      // ignore: avoid_print
      print(
        'POI: ${poi.name} | Distance: ${distance.toStringAsFixed(2)}m | Bearing: ${bearing.toStringAsFixed(1)}° | '
        'Heading: ${userHeading.toStringAsFixed(1)}° | Difference: ${angleDifference.toStringAsFixed(1)}° | '
        'Tolerance: ${tolerance.toStringAsFixed(1)}° | Range: $inRange | Facing: $facingIt',
      );
    }

    if (inRange && facingIt) candidates.add(poi);
  }

  return candidates;
}

List<Poi> rankCandidates(double userLat, double userLon, double userHeading, List<Poi> candidates) {
  candidates.sort((a, b) {
    final double distA = haversineDistance(userLat, userLon, a.lat, a.long);
    final double distB = haversineDistance(userLat, userLon, b.lat, b.long);
    return distA.compareTo(distB);
  });
  return candidates;
}

MatchResult runMatchingEngine(
  double userLat,
  double userLon,
  double userHeading,
  List<Poi> allPOIs, {
  bool debugLogging = false,
}) {
  final List<Poi> candidates = findCandidatePOIs(userLat, userLon, userHeading, allPOIs, debugLogging: debugLogging);

  if (candidates.isEmpty) return MatchResult();
  if (candidates.length == 1) return MatchResult(singleMatch: candidates[0]);

  return MatchResult(queue: rankCandidates(userLat, userLon, userHeading, candidates));
}