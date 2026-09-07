import 'package:flutter_test/flutter_test.dart';
import 'package:disha_vaani/models/monument.dart';
import 'package:disha_vaani/models/interest_profile.dart';
import 'package:disha_vaani/services/recommendation_engine.dart';

void main() {
  group('RecommendationEngine', () {
    final haveli = Monument(
      id: 'haveli_dharampura',
      name: 'Haveli Dharampura',
      description: 'Historic architectural haveli in Old Delhi',
      lat: 28.6562,
      long: 77.2310,
      categories: ['architecture', 'history', 'food'],
      siteType: SiteType.private,
      ownerContact: 'contact@havelidharampura.com',
    );

    final farMarket = Monument(
      id: 'far_market',
      name: 'Distant Market',
      description: 'Faraway shopping district',
      lat: 29.1000,
      long: 78.0000,
      categories: ['shopping', 'food'],
      siteType: SiteType.government,
    );

    test('ranks nearby matching monument over distant candidate', () {
      // Pass the 1 positional Map argument expected by InterestProfile
      final profile = InterestProfile({
        'history': 1.0,
        'architecture': 0.9,
        'food': 0.5,
        'shopping': 0.1,
      });

      // User location right near Haveli Dharampura
      final results = RecommendationEngine.rank(
        candidates: [haveli, farMarket],
        profile: profile,
        currentLat: 28.6560,
        currentLon: 77.2312,
        maxRadiusMeters: 3000.0,
      );

      // farMarket (~100km away) should be filtered out by maxRadiusMeters
      expect(results.length, equals(1));
      expect(results.first.monument.id, equals('haveli_dharampura'));
      expect(results.first.distanceMeters, lessThan(100.0));
    });

    test('respects excludeMonumentId parameter', () {
      final profile = InterestProfile({
        'history': 1.0,
        'architecture': 0.9,
      });

      final results = RecommendationEngine.rank(
        candidates: [haveli],
        profile: profile,
        currentLat: 28.6560,
        currentLon: 77.2312,
        excludeMonumentId: 'haveli_dharampura',
      );

      expect(results, isEmpty);
    });

    test('calculates correct category interest average', () {
      // Monument with two categories: 1.0 and 0.0 -> average should be 0.5
      final mixedMonument = Monument(
        id: 'mixed_site',
        name: 'Mixed Site',
        description: 'Test site',
        lat: 28.6561,
        long: 77.2311,
        categories: ['history', 'shopping'],
        siteType: SiteType.government,
      );

      final profile = InterestProfile({
        'history': 1.0,
        'shopping': 0.0,
      });

      final results = RecommendationEngine.rank(
        candidates: [mixedMonument],
        profile: profile,
        currentLat: 28.6560,
        currentLon: 77.2312,
      );

      expect(results.first.interestScore, closeTo(0.5, 0.01));
    });
  });
}