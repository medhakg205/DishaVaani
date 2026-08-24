//basic class structure for each poi, final means cant be changed
class Poi {
  final String id;
  final String monumentId;
  final String name;
  final double lat;
  final double long;
  final double bearingTolerance;
  final Map<String, String> audioUrls;
  final Map<String, String> scripts;

  const Poi({
    required this.id,
    required this.monumentId,
    required this.name,
    required this.lat,
    required this.long,
    required this.bearingTolerance,
    required this.audioUrls,
    required this.scripts,
  });

  factory Poi.fromFirestore(String id, Map<String, dynamic> data) {
    final rawAudioUrls = data['audioUrls'] as Map<dynamic, dynamic>?;
    final Map<String, String> audioUrlsMap = rawAudioUrls != null
        ? rawAudioUrls.map((key, value) => MapEntry(key.toString(), value.toString()))
        : const {};

    final rawScripts = data['scripts'] as Map<dynamic, dynamic>?;
    final Map<String, String> scriptsMap = rawScripts != null
        ? rawScripts.map((key, value) => MapEntry(key.toString(), value.toString()))
        : const {};

    return Poi(
      id: id,
      monumentId: (data['monumentId'] as String? ?? '').trim(),
      name: data['name'] as String? ?? 'Unnamed POI',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      long: (data['long'] as num?)?.toDouble() ?? 0.0,
      bearingTolerance: (data['bearingTolerance'] as num?)?.toDouble() ?? 25.0,
      audioUrls: audioUrlsMap,
      scripts: scriptsMap,
    );
  }

  String getScript(String languageCode) {
    return scripts[languageCode] ?? scripts['en'] ?? '';
  }

  String getAudioUrl(String languageCode) {
    return audioUrls[languageCode] ?? audioUrls['en'] ?? '';
  }
}