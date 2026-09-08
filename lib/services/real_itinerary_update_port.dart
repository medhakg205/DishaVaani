import '../models/monument.dart';
import '../models/itinerary_stop.dart';
import 'itinerary.dart';
import 'itinerary_update_port.dart';

class RealItineraryUpdatePort implements ItineraryUpdatePort {
  static int _timeToMinutes(String timeStr, {int defaultMinutes = 600}) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0].trim());
        final m = int.parse(parts[1].trim().split(' ')[0]);
        return h * 60 + m;
      }
    } catch (_) {}
    return defaultMinutes;
  }

  static String _minutesToTime(int totalMinutes) {
    final clamped = totalMinutes % (24 * 60);
    final h = clamped ~/ 60;
    final m = clamped % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> insertStopAfter({
    required int afterIndex,
    required Monument monument,
  }) async {
    final currentStops = await ItineraryService.loadStops();

    // 1. Calculate dynamic start time based on the previous stop
    int newStartMin;
    DateTime stopDate = DateTime.now();

    if (afterIndex >= 0 && afterIndex < currentStops.length) {
      final prevStop = currentStops[afterIndex];
      newStartMin = _timeToMinutes(prevStop.endTime);
      stopDate = prevStop.date;
    } else if (currentStops.isNotEmpty) {
      final lastStop = currentStops.last;
      newStartMin = _timeToMinutes(lastStop.endTime);
      stopDate = lastStop.date;
    } else {
      newStartMin = 600; // 10:00 AM default
    }

    const durationMin = 60; // 1 hour visit for new detour / stop
    final newEndMin = newStartMin + durationMin;

    final newStop = ItineraryStop(
      monumentId: monument.id,
      placeName: monument.name,
      lat: monument.lat,
      long: monument.long,
      date: stopDate,
      startTime: _minutesToTime(newStartMin),
      endTime: _minutesToTime(newEndMin),
    );

    final updatedStops = List<ItineraryStop>.from(currentStops);
    final insertPosition = afterIndex + 1;

    if (insertPosition >= updatedStops.length) {
      updatedStops.add(newStop);
    } else {
      updatedStops.insert(insertPosition, newStop);
    }

    // 2. Adjust subsequent stops forward if their start time clashes with the inserted stop
    int nextAvailableStartMin = newEndMin;
    for (int i = insertPosition + 1; i < updatedStops.length; i++) {
      final existingStop = updatedStops[i];
      final currentStartMin = _timeToMinutes(existingStop.startTime);
      final currentEndMin = _timeToMinutes(existingStop.endTime);
      final duration = (currentEndMin > currentStartMin)
          ? (currentEndMin - currentStartMin)
          : 60;

      if (currentStartMin < nextAvailableStartMin) {
        final shiftedStart = nextAvailableStartMin;
        final shiftedEnd = shiftedStart + duration;
        updatedStops[i] = ItineraryStop(
          poiId: existingStop.poiId,
          monumentId: existingStop.monumentId,
          placeName: existingStop.placeName,
          lat: existingStop.lat,
          long: existingStop.long,
          date: existingStop.date,
          startTime: _minutesToTime(shiftedStart),
          endTime: _minutesToTime(shiftedEnd),
        );
        nextAvailableStartMin = shiftedEnd;
      } else {
        nextAvailableStartMin = currentEndMin;
      }
    }

    await ItineraryService.saveStops(updatedStops);
  }

  @override
  Future<void> replaceStop({
    required int index,
    required Monument monument,
  }) async {
    final currentStops = await ItineraryService.loadStops();
    if (index < 0 || index >= currentStops.length) return;

    final existingStop = currentStops[index];

    // Replaces the skipped stop while preserving its scheduled time slot
    final newStop = ItineraryStop(
      monumentId: monument.id,
      placeName: monument.name,
      lat: monument.lat,
      long: monument.long,
      date: existingStop.date,
      startTime: existingStop.startTime,
      endTime: existingStop.endTime,
    );

    final updatedStops = List<ItineraryStop>.from(currentStops);
    updatedStops[index] = newStop;

    await ItineraryService.saveStops(updatedStops);
  }
}