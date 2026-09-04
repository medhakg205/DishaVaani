// sensor_service.dart — fused GPS + compass reading stream
import 'dart:async';
import 'dart:io';

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class SensorReading {
  final double lat;
  final double long;
  final double heading;

  SensorReading({required this.lat, required this.long, required this.heading});
}

class SensorService {
  double? _lastHeading;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;

  final StreamController<SensorReading> _controller = StreamController<SensorReading>.broadcast();
  Stream<SensorReading> get readings => _controller.stream;

  LocationSettings _getLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(accuracy: LocationAccuracy.best, distanceFilter: 1, intervalDuration: const Duration(milliseconds: 1000));
    } else if (Platform.isIOS) {
      return AppleSettings(accuracy: LocationAccuracy.best, activityType: ActivityType.fitness, distanceFilter: 1, pauseLocationUpdatesAutomatically: false);
    }
    return const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 1);
  }

  Future<void> start() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission not granted');
    }

    // BUG FIX: original also ran a Timer.periodic polling getCurrentPosition()
    // every second alongside this stream — two competing location fetches
    // draining battery and racing each other. Stream alone is enough.
    _positionSub = Geolocator.getPositionStream(locationSettings: _getLocationSettings()).listen((position) {
      _lastPosition = position;
      _emit();
    });

    _compassSub = FlutterCompass.events?.listen((event) {
      final raw = event.heading;
      if (raw == null) return;

      if (_lastHeading == null) {
        _lastHeading = raw;
      } else {
        double delta = raw - _lastHeading!;
        if (delta > 180) delta -= 360;
        if (delta < -180) delta += 360;
        _lastHeading = (_lastHeading! + 0.2 * delta + 360) % 360;
      }
      _emit();
    });
  }

  void _emit() {
    if (_lastPosition != null) {
      _controller.add(SensorReading(lat: _lastPosition!.latitude, long: _lastPosition!.longitude, heading: _lastHeading ?? 0));
    }
  }

  void dispose() {
    _positionSub?.cancel();
    _compassSub?.cancel();
    _controller.close();
  }
}