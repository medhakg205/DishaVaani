//basic class structure for each poi, final means cant be changed
class Poi {
  final String id;
  final String name;
  final double lat;
  final double long;
  final double bearingTolerance;
  final String audioUrl;
  final String scriptText;

// constructor- 
  Poi({
    required this.id,
    required this.name,
    required this.lat,
    required this.long,
    required this.bearingTolerance,
    required this.audioUrl,
    required this.scriptText,
  });

//translator function-reads each expected key out of that map that firebase sends and builds a proper Poi object from it.
  factory Poi.fromFirestore(String id, Map<String, dynamic> data) {
    return Poi(
      id: id,
      name: data['name'] ?? '',
      lat: (data['lat'] ?? 0).toDouble(),
      long: (data['long'] ?? 0).toDouble(),
      bearingTolerance: (data['bearingTolerance'] ?? 25).toDouble(),
      audioUrl: data['audioUrl'] ?? '',
      scriptText: data['scriptText'] ?? '',
    );
  }
}