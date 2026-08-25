import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

class SensorReading {
  final double lat;
  final double long;
  final double heading;

  SensorReading({
    required this.lat,
    required this.long,
    required this.heading,
  });
}

class SensorService {
  double? _lastHeading;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;

  final StreamController<SensorReading> _controller =
      StreamController<SensorReading>.broadcast();

  Stream<SensorReading> get readings => _controller.stream;

  Future<void> start() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission not granted');
    }


      _positionSub = Geolocator.getPositionStream(

        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
      ),
      ).listen((position) {
      _lastPosition = position;
      print('GPS UPDATE: lat=${position.latitude}, long=${position.longitude}');
      _emit();
    }, onError: (error) {
      print('GPS STREAM ERROR: $error');
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
    if (_lastPosition != null && _lastHeading != null) {
      _controller.add(SensorReading(
        lat: _lastPosition!.latitude,
        long: _lastPosition!.longitude,
        heading: _lastHeading!,
      ));
    }
  }

  void dispose() {
    _positionSub?.cancel();
    _compassSub?.cancel();
    _controller.close();
  }
}