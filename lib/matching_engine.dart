import 'dart:math';

import 'models/poi.dart';

class MatchResult {
  final Poi? singleMatch;
  final List<Poi> queue;
  final bool hasMatch;

  MatchResult({
    this.singleMatch,
    this.queue = const [],
  }) : hasMatch = singleMatch != null || queue.isNotEmpty;
}

// ------------------------------------------------------------
// DISTANCE
// ------------------------------------------------------------

double haversineDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const double earthRadius = 6371000; // meters

  double toRadians(double degree) => degree * pi / 180;

  final double dLat = toRadians(lat2 - lat1);
  final double dLon = toRadians(lon2 - lon1);

  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(toRadians(lat1)) *
          cos(toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

// ------------------------------------------------------------
// BEARING
// ------------------------------------------------------------

double calculateBearing(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  double toRadians(double degree) => degree * pi / 180;
  double toDegrees(double radian) => radian * 180 / pi;

  final double dLon = toRadians(lon2 - lon1);

  final double lat1Rad = toRadians(lat1);
  final double lat2Rad = toRadians(lat2);

  final double y = sin(dLon) * cos(lat2Rad);

  final double x =
      cos(lat1Rad) * sin(lat2Rad) -
      sin(lat1Rad) *
          cos(lat2Rad) *
          cos(dLon);

  final double bearing =
      toDegrees(atan2(y, x));

  return (bearing + 360) % 360;
}

// ------------------------------------------------------------
// ANGLE DIFFERENCE
// ------------------------------------------------------------

double bearingDifference(
  double heading,
  double bearing,
) {
  double difference = (bearing - heading).abs();

  if (difference > 180) {
    difference = 360 - difference;
  }

  return difference;
}

// ------------------------------------------------------------
// CHECK IF USER IS FACING POI
// ------------------------------------------------------------

bool isWithinToleranceCone(
  double heading,
  double bearing, {
  double tolerance = 25,
}) {
  final double difference =
      bearingDifference(heading, bearing);

  return difference <= tolerance;
}

// ------------------------------------------------------------
// FIND CANDIDATE POIs
// ------------------------------------------------------------

List<Poi> findCandidatePOIs(
  double userLat,
  double userLon,
  double userHeading,
  List<Poi> allPOIs,
) {
  final List<Poi> candidates = [];

  for (final Poi poi in allPOIs) {
    final double distance = haversineDistance(
      userLat,
      userLon,
      poi.lat,
      poi.long,
    );

    final double bearing = calculateBearing(
      userLat,
      userLon,
      poi.lat,
      poi.long,
    );

    final double tolerance =
        poi.bearingTolerance > 0
            ? poi.bearingTolerance
            : 25;

    final double angleDifference =
        bearingDifference(
      userHeading,
      bearing,
    );

    // --------------------------------------------------------
    // DEMO RANGE
    //
    // Previously:
    // distance >= 5 && distance <= 15
    //
    // Now:
    // 0 <= distance <= 100
    //
    // This makes testing much easier.
    // --------------------------------------------------------

    final bool inRange =
        distance >= 0 && distance <= 100;

    final bool facingIt =
        angleDifference <= tolerance;

    // DEBUG LOG
    print(
      'POI: ${poi.name} | '
      'Distance: ${distance.toStringAsFixed(2)}m | '
      'Bearing: ${bearing.toStringAsFixed(1)}° | '
      'Heading: ${userHeading.toStringAsFixed(1)}° | '
      'Difference: ${angleDifference.toStringAsFixed(1)}° | '
      'Tolerance: ${tolerance.toStringAsFixed(1)}° | '
      'Range: $inRange | '
      'Facing: $facingIt',
    );

    if (inRange && facingIt) {
      candidates.add(poi);
    }
  }

  return candidates;
}

// ------------------------------------------------------------
// RANK CANDIDATES
// ------------------------------------------------------------

List<Poi> rankCandidates(
  double userLat,
  double userLon,
  double userHeading,
  List<Poi> candidates,
) {
  candidates.sort((a, b) {
    final double distA = haversineDistance(
      userLat,
      userLon,
      a.lat,
      a.long,
    );

    final double distB = haversineDistance(
      userLat,
      userLon,
      b.lat,
      b.long,
    );

    return distA.compareTo(distB);
  });

  return candidates;
}

// ------------------------------------------------------------
// MAIN MATCHING ENGINE
// ------------------------------------------------------------

MatchResult runMatchingEngine(
  double userLat,
  double userLon,
  double userHeading,
  List<Poi> allPOIs,
) {
  final List<Poi> candidates =
      findCandidatePOIs(
    userLat,
    userLon,
    userHeading,
    allPOIs,
  );

  if (candidates.isEmpty) {
    return MatchResult();
  }

  if (candidates.length == 1) {
    return MatchResult(
      singleMatch: candidates[0],
    );
  }

  final List<Poi> ranked =
      rankCandidates(
    userLat,
    userLon,
    userHeading,
    candidates,
  );

  return MatchResult(
    queue: ranked,
  );
}