import '../models/itinerary_stop.dart';

class InferredStop {
  final ItineraryStop stop;
  final double distanceMeters;

  InferredStop(this.stop, this.distanceMeters);
}

InferredStop? inferCurrentStop({
  required List<ItineraryStop> stops,
  required DateTime now,
  required double userLat,
  required double userLong,
  required double Function(double lat1, double long1, double lat2, double long2) distanceCalculator,
  double maxDistanceMeters = 200,
  int timeBufferMinutes = 15,
}) {
  InferredStop? best;

  for (final stop in stops) {
    if (stop.lat == null || stop.long == null) continue; // unresolved stop, skip

    final start = _parseTimeOnDate(stop.date, stop.startTime).subtract(Duration(minutes: timeBufferMinutes));
    final end = _parseTimeOnDate(stop.date, stop.endTime).add(Duration(minutes: timeBufferMinutes));
    if (now.isBefore(start) || now.isAfter(end)) continue;

    final distance = distanceCalculator(userLat, userLong, stop.lat!, stop.long!);
    if (distance > maxDistanceMeters) continue;

    // Closer stop wins if two are both plausible right now.
    if (best == null || distance < best.distanceMeters) {
      best = InferredStop(stop, distance);
    }
  }

  return best;
}

DateTime _parseTimeOnDate(DateTime date, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
}