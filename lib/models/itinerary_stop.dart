import 'poi.dart';
class ItineraryStop {
  final String? poiId;
  final String? monumentId;
  final String placeName;
  final double? lat;  // NEW — filled in once matched to a real POI
  final double? long; // NEW
  final DateTime date;
  final String startTime;
  final String endTime;

  ItineraryStop({
    this.poiId,
    this.monumentId,
    required this.placeName,
    this.lat,
    this.long,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'poiId': poiId,
      'monumentId': monumentId,
      'placeName': placeName,
      'lat': lat,
      'long': long,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory ItineraryStop.fromFirestore(Map<String, dynamic> data) {
    return ItineraryStop(
      poiId: data['poiId'] as String?,
      monumentId: data['monumentId'] as String?,
      placeName: data['placeName'] as String,
      lat: (data['lat'] as num?)?.toDouble(),
      long: (data['long'] as num?)?.toDouble(),
      date: DateTime.parse(data['date'] as String),
      startTime: data['startTime'] as String,
      endTime: data['endTime'] as String,
    );
  }

  factory ItineraryStop.fromJson(Map<String, dynamic> json) {
    return ItineraryStop(
      placeName: json['placeName'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  ItineraryStop copyWithMatch(Poi matchedPoi) {
    return ItineraryStop(
      poiId: matchedPoi.id,
      monumentId: matchedPoi.monumentId,
      placeName: placeName,
      lat: matchedPoi.lat,
      long: matchedPoi.long,
      date: date,
      startTime: startTime,
      endTime: endTime,
    );
  }
}