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
    final scripts = data['scripts'];
    final audioUrls = data['audioUrls'];
    return Poi(
      id: id,
      monumentId: normalizeMonumentId(data['monumentId'] as String? ?? ''),
      name: data['name'] as String? ?? 'Unnamed POI',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      long: (data['long'] as num?)?.toDouble() ?? 0.0,
      bearingTolerance: (data['bearingTolerance'] as num?)?.toDouble() ?? 25.0,
      audioUrl:
          (audioUrls is Map ? audioUrls['en'] : null) as String? ??
          data['audioUrl'] as String? ??
          '',
      scriptText:
          (scripts is Map ? scripts['en'] : null) as String? ??
          data['scriptText'] as String? ??
          '',
    );
  }

  static String normalizeMonumentId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
