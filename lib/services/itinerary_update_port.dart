import 'package:flutter/foundation.dart';
import '../models/monument.dart';

abstract class ItineraryUpdatePort {
  Future<void> insertStopAfter({required int afterIndex, required Monument monument});
  Future<void> replaceStop({required int index, required Monument monument});
}

class NoOpItineraryUpdatePort implements ItineraryUpdatePort {
  @override
  Future<void> insertStopAfter({required int afterIndex, required Monument monument}) async {
    debugPrint('[stub] would insert ${monument.name} after stop $afterIndex');
  }

  @override
  Future<void> replaceStop({required int index, required Monument monument}) async {
    debugPrint('[stub] would replace stop $index with ${monument.name}');
  }
}