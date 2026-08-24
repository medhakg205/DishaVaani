import 'dart:math';

class POI {
  final String name;
  final double lat;
  final double lon;

  POI(this.name, this.lat, this.lon);
}

class MatchResult {
  final POI? singleMatch;
  final List<POI> queue;
  final bool hasMatch;

  MatchResult({this.singleMatch, this.queue = const []})
      : hasMatch = singleMatch != null || queue.isNotEmpty;
}

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // meters

  double toRadians(double degree) => degree * pi / 180;

  double dLat = toRadians(lat2 - lat1);
  double dLon = toRadians(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRadians(lat1)) * cos(toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c; // distance in meters
}

double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
  double toRadians(double degree) => degree * pi / 180;
  double toDegrees(double radian) => radian * 180 / pi;

  double dLon = toRadians(lon2 - lon1);
  double lat1Rad = toRadians(lat1);
  double lat2Rad = toRadians(lat2);

  double y = sin(dLon) * cos(lat2Rad);
  double x = cos(lat1Rad) * sin(lat2Rad) -
      sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

  double bearing = toDegrees(atan2(y, x));

  return (bearing + 360) % 360; // normalize to 0-360
}

bool isWithinToleranceCone(double heading, double bearing, {double tolerance = 25}) {
  double diff = bearing - heading;

  diff = (diff + 180) % 360 - 180;
  if (diff < -180) diff += 360;

  return diff.abs() <= tolerance;
}

List<POI> findCandidatePOIs(double userLat, double userLon, double userHeading, List<POI> allPOIs) {
  List<POI> candidates = [];

  for (POI poi in allPOIs) {
    double distance = haversineDistance(userLat, userLon, poi.lat, poi.lon);
    double bearing = calculateBearing(userLat, userLon, poi.lat, poi.lon);

    bool inRange = distance >= 5 && distance <= 15;
    bool facingIt = isWithinToleranceCone(userHeading, bearing);

    if (inRange && facingIt) {
      candidates.add(poi);
    }
  }

  return candidates;
}

List<POI> rankCandidates(double userLat, double userLon, double userHeading, List<POI> candidates) {
  candidates.sort((a, b) {
    double distA = haversineDistance(userLat, userLon, a.lat, a.lon);
    double distB = haversineDistance(userLat, userLon, b.lat, b.lon);
    return distA.compareTo(distB);
  });

  return candidates;
}

MatchResult runMatchingEngine(double userLat, double userLon, double userHeading, List<POI> allPOIs) {
  List<POI> candidates = findCandidatePOIs(userLat, userLon, userHeading, allPOIs);

  if (candidates.isEmpty) {
    return MatchResult();
  } else if (candidates.length == 1) {
    return MatchResult(singleMatch: candidates[0]);
  } else {
    List<POI> ranked = rankCandidates(userLat, userLon, userHeading, candidates);
    return MatchResult(queue: ranked);
  }
}

void main() {
  double userLat = 12.9716;
  double userLon = 77.5946;
  double userHeading = 44;

  List<POI> testPOIs = [
    POI('Old Fort Gate', 12.97165, 77.59468),
    POI('Ancient Temple', 12.9720, 77.5950),
    POI('Watch Tower', 12.97162, 77.59465),
  ];

  MatchResult result = runMatchingEngine(userLat, userLon, userHeading, testPOIs);

  if (result.singleMatch != null) {
    print('Playing directly: ${result.singleMatch!.name}');
  } else if (result.queue.isNotEmpty) {
    print('Clash — ranked queue:');
    for (int i = 0; i < result.queue.length; i++) {
      print('${i + 1}. ${result.queue[i].name}');
    }
  } else {
    print('No match found.');
  }
}
/*void main() {
  double distance = haversineDistance(12.9716, 77.5946, 12.9720, 77.5950);
  print('Distance: ${distance.toStringAsFixed(2)} meters');

  double bearing = calculateBearing(12.9716, 77.5946, 12.9720, 77.5950);
  print('Bearing: ${bearing.toStringAsFixed(2)} degrees');

  bool facingPOI = isWithinToleranceCone(40, bearing);
  print('Facing POI: $facingPOI');
}*/