import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:disha_vaani/models/itinerary_stop.dart';
import 'package:disha_vaani/widgets/itinerary_stop_card.dart';

void main() {
  group('ItineraryStopCard Widget Tests', () {
    testWidgets('renders stop place name, times, and all 3 action buttons', (tester) async {
      bool skipCalled = false;
      bool finishEarlyCalled = false;
      bool detourCalled = false;
      bool cardTapped = false;

      final testStop = ItineraryStop(
        placeName: 'Qutub Minar',
        monumentId: 'qutub_minar',
        date: DateTime.now(),
        startTime: '10:00',
        endTime: '11:30',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItineraryStopCard(
              stop: testStop,
              stopIndex: 0,
              isSelected: true,
              isAvailable: true,
              onTap: () => cardTapped = true,
              onSkip: () => skipCalled = true,
              onFinishEarly: () => finishEarlyCalled = true,
              onRequestDetour: () => detourCalled = true,
            ),
          ),
        ),
      );

      // Verify place name and times are displayed
      expect(find.text('Qutub Minar'), findsOneWidget);
      expect(find.text('10:00 - 11:30'), findsOneWidget);

      // Verify all 3 action buttons are rendered
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Finish Early'), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);

      // Test tapping Skip
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(skipCalled, isTrue);

      // Test tapping Finish Early
      await tester.tap(find.text('Finish Early'));
      await tester.pump();
      expect(finishEarlyCalled, isTrue);

      // Test tapping Detour icon
      await tester.tap(find.byIcon(Icons.explore_outlined));
      await tester.pump();
      expect(detourCalled, isTrue);

      // Test card tap
      await tester.tap(find.text('Qutub Minar'));
      await tester.pump();
      expect(cardTapped, isTrue);
    });
  });
}
