import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:disha_vaani/models/poi.dart';
import 'package:disha_vaani/services/scripting_settings.dart';
import 'package:disha_vaani/widgets/dynamic_scripting_toggle.dart';
import 'package:disha_vaani/screens/point_detect.dart';

void main() {
  setUp(() {
    // Reset to default before each test
    ScriptingSettings().toggleDynamicScripting(true);
  });

  group('ScriptingSettings', () {
    test('defaults to dynamic scripting enabled (true)', () {
      final settings = ScriptingSettings();
      expect(settings.isDynamicScriptingEnabled, isTrue);
    });

    test('toggles dynamic scripting and notifies listeners', () {
      final settings = ScriptingSettings();
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }
      settings.addListener(listener);

      settings.toggleDynamicScripting(false);
      expect(settings.isDynamicScriptingEnabled, isFalse);
      expect(notifyCount, equals(1));

      settings.toggleDynamicScripting(true);
      expect(settings.isDynamicScriptingEnabled, isTrue);
      expect(notifyCount, equals(2));

      settings.removeListener(listener);
    });
  });

  group('DynamicScriptingToggle Widget', () {
    testWidgets('renders full toggle card with title, subtitle, icon and switch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicScriptingToggle(),
          ),
        ),
      );

      expect(find.text('Dynamic Scripting (AI)'), findsOneWidget);
      expect(find.text('AI-personalized POI narration'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('toggling switch updates ScriptingSettings and visually flips switch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicScriptingToggle(),
          ),
        ),
      );

      expect(ScriptingSettings().isDynamicScriptingEnabled, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      // Tap the switch to turn OFF
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(ScriptingSettings().isDynamicScriptingEnabled, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.text('Standard pre-recorded narration'), findsOneWidget);

      // Tap again to turn ON
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(ScriptingSettings().isDynamicScriptingEnabled, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text('AI-personalized POI narration'), findsOneWidget);
    });

    testWidgets('renders compact toggle mode for AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: DynamicScriptingToggle(isCompact: true),
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      // Compact mode should not render the full subtitle
      expect(find.text('AI-personalized POI narration'), findsNothing);
    });
  });

  group('Execution Flow & POI Scripting Branching', () {
    test('onPoiDetected branches correctly depending on isDynamicScriptingEnabled', () {
      final settings = ScriptingSettings();

      settings.toggleDynamicScripting(true);
      expect(settings.isDynamicScriptingEnabled, isTrue);
      onPoiDetected('poi_test_1', 'device_123');

      settings.toggleDynamicScripting(false);
      expect(settings.isDynamicScriptingEnabled, isFalse);
      onPoiDetected('poi_test_1', 'device_123');
    });

    test('poi audio fallback uses static audio when dynamic scripting is disabled', () {
      final settings = ScriptingSettings();
      settings.toggleDynamicScripting(false);

      final testPoi = Poi(
        id: 'test_poi',
        monumentId: 'qutub_minar',
        name: 'Iron Pillar',
        lat: 28.5244,
        long: 77.1855,
        bearingTolerance: 25.0,
        audioUrls: {
          'en': 'https://static.audio/iron_pillar_en.mp3',
          'hi': 'https://static.audio/iron_pillar_hi.mp3',
        },
        scripts: {
          'en': 'Static narration script for Iron Pillar',
        },
      );

      expect(testPoi.audioUrls['en'], equals('https://static.audio/iron_pillar_en.mp3'));
      expect(testPoi.getAudioUrl('en'), equals('https://static.audio/iron_pillar_en.mp3'));
      expect(settings.isDynamicScriptingEnabled, isFalse);
    });

    test('poi scripts map can be updated dynamically with personalized script', () {
      final testPoi = Poi(
        id: 'test_poi',
        monumentId: 'qutub_minar',
        name: 'Iron Pillar',
        lat: 28.5244,
        long: 77.1855,
        bearingTolerance: 25.0,
        audioUrls: {'en': 'https://static.audio/en.mp3'},
        scripts: {'en': 'Base historical description'},
      );

      expect(testPoi.getScript('en'), equals('Base historical description'));

      // Simulate Gemini-personalized script arriving
      const personalizedScript = 'A marvel of ancient Indian metallurgy, the Iron Pillar showcases rust-resistant forging techniques.';
      testPoi.scripts['en'] = personalizedScript;

      expect(testPoi.getScript('en'), equals(personalizedScript));
    });

    test('poi correctly parses and retrieves readAloudUrls for static read-aloud playback', () {
      final data = {
        'monumentId': 'qutub_minar',
        'name': 'Iron Pillar',
        'lat': 28.5244,
        'long': 77.1855,
        'bearingTolerance': 25.0,
        'audioUrls': {
          'en': 'https://static.audio/iron_pillar_en_prerecorded.mp3',
        },
        'readAloudUrls': {
          'en': 'https://supabase.audio/tts_cached/iron_pillar_en_read_aloud.mp3',
          'hi': 'https://supabase.audio/tts_cached/iron_pillar_hi_read_aloud.mp3',
        },
        'scripts': {
          'en': 'Static narration script for Iron Pillar',
        },
      };

      final poi = Poi.fromFirestore('poi_iron_pillar', data);

      // Pre-recorded human voice URL
      expect(poi.getAudioUrl('en'), equals('https://static.audio/iron_pillar_en_prerecorded.mp3'));
      // Read-aloud TTS generated URLs
      expect(poi.getReadAloudUrl('en'), equals('https://supabase.audio/tts_cached/iron_pillar_en_read_aloud.mp3'));
      expect(poi.getReadAloudUrl('hi'), equals('https://supabase.audio/tts_cached/iron_pillar_hi_read_aloud.mp3'));
      expect(poi.getReadAloudUrl('ta'), equals(''));
    });
  });
}
