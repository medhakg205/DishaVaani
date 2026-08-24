//basic class structure for each poi, final means cant be changed
class Poi {
  final String id;
  final String monumentId;
  final String name;
  final double lat;
  final double long;
  final double bearingTolerance;
  final String audioUrl;
  final String scriptText;

  const Poi({
    required this.id,
    required this.monumentId,
    required this.name,
    required this.lat,
    required this.long,
    required this.bearingTolerance,
    required this.audioUrl,
    required this.scriptText,
  });

  factory Poi.fromFirestore(String id, Map<String, dynamic> data) {
    return Poi(
      id: id,
      monumentId: (data['monumentId'] as String? ?? '').trim(),
      name: data['name'] as String? ?? 'Unnamed POI',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      long: (data['long'] as num?)?.toDouble() ?? 0.0,
      bearingTolerance: (data['bearingTolerance'] as num?)?.toDouble() ?? 25.0,
      audioUrl: data['audioUrl'] as String? ?? '',
      scriptText: data['scriptText'] as String? ?? '',
    );
  }
}
