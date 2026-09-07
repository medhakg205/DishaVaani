/// Canonical shape of a traveler's interest profile — the same 12 keys
/// interest_quiz.dart already scores into `scores`. Wrapping it in a class
/// just gives every other file one typed thing to pass around instead of
/// a raw Map, and a stable way to go to/from Firestore JSON.
class InterestProfile {
  static const List<String> categories = [
    'history',
    'architecture',
    'military',
    'religion',
    'politics',
    'food',
    'shopping',
    'relaxation',
    'art',
    'culture',
    'nature',
    'crafts',
  ];

  final Map<String, double> weights;

  InterestProfile(Map<String, double> weights) : weights = _normalize(weights);

  factory InterestProfile.empty() {
    return InterestProfile({for (final c in categories) c: 0.0});
  }

  factory InterestProfile.fromJson(Map<String, dynamic> json) {
    final map = <String, double>{};
    for (final c in categories) {
      final value = json[c];
      map[c] = (value is num) ? value.toDouble() : 0.0;
    }
    return InterestProfile(map);
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(weights);

  static Map<String, double> _normalize(Map<String, double> input) {
    final out = <String, double>{};
    for (final c in categories) {
      final v = input[c] ?? 0.0;
      out[c] = v.clamp(0.0, 1.0);
    }
    return out;
  }

  double operator [](String category) => weights[category] ?? 0.0;

  @override
  String toString() => 'InterestProfile($weights)';
}