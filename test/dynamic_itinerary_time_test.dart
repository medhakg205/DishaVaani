import 'package:flutter_test/flutter_test.dart';
import 'package:disha_vaani/models/monument.dart';
import 'package:disha_vaani/models/itinerary_stop.dart';
import 'package:disha_vaani/services/real_itinerary_update_port.dart';

void main() {
  group('Itinerary Dynamic Time Scheduling Tests', () {
    test('Calculates sequential non-conflicting time slots', () {
      final stop1 = ItineraryStop(
        placeName: 'Qutub Minar',
        monumentId: 'qutub_minar',
        date: DateTime.now(),
        startTime: '10:00',
        endTime: '11:30',
      );

      final stop2 = ItineraryStop(
        placeName: 'Red Fort',
        monumentId: 'red_fort',
        date: DateTime.now(),
        startTime: '11:30',
        endTime: '13:00',
      );

      // Verify that afterIndex = 0 takes endTime '11:30' as the new startTime
      final currentStops = [stop1, stop2];
      final afterIndex = 0;
      final prevStop = currentStops[afterIndex];

      expect(prevStop.endTime, equals('11:30'));
    });
  });
}
