import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DemoController extends ChangeNotifier {
  bool demoMode = false;
  bool autoPlay = false;

  double heading = 0.0;
  double latitude = 28.6139;
  double longitude = 77.2090;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _autoPlayTimer;

  double _ax = 0.0;
  double _ay = 0.0;
  double _az = 9.8;
  double _lastHeading = 0.0;

  DemoController() {
    _startSensors();
  }

  void _startSensors() {
    _accelerometerSubscription =
        accelerometerEventStream().listen((event) {
      _ax = event.x;
      _ay = event.y;
      _az = event.z;
    });

    _magnetometerSubscription =
        magnetometerEventStream().listen((event) {
      // Demo mode freezes the real sensor heading.
      if (demoMode) return;

      _calculateHeading(event.x, event.y, event.z);
    });
  }

  void _calculateHeading(double mx, double my, double mz) {
    final magnitude = math.sqrt(
      _ax * _ax + _ay * _ay + _az * _az,
    );

    if (magnitude == 0) return;

    final ax = _ax / magnitude;
    final ay = _ay / magnitude;
    final az = _az / magnitude;

    final pitch = math.asin((-ax).clamp(-1.0, 1.0));
    final roll = math.atan2(ay, az);

    final x =
        mx * math.cos(pitch) +
        mz * math.sin(pitch);

    final y =
        mx * math.sin(roll) * math.sin(pitch) +
        my * math.cos(roll) -
        mz * math.sin(roll) * math.cos(pitch);

    var newHeading = math.atan2(y, x) * 180 / math.pi;

    if (newHeading < 0) {
      newHeading += 360;
    }

    var difference = newHeading - _lastHeading;

    if (difference > 180) difference -= 360;
    if (difference < -180) difference += 360;

    heading = (_lastHeading + difference * 0.20) % 360;

    if (heading < 0) {
      heading += 360;
    }

    _lastHeading = heading;
    notifyListeners();
  }

  // Demo OFF = real phone sensor controls heading.
  // Demo ON = freeze current heading until slider/Auto Play changes it.
  void setDemoMode(bool enabled) {
    demoMode = enabled;

    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    autoPlay = false;

    _lastHeading = heading;

    notifyListeners();
  }

  // Manual slider. Only active in Demo Mode.
  void setHeading(double value) {
    if (!demoMode) return;

    heading = value.clamp(0.0, 360.0);
    _lastHeading = heading;

    notifyListeners();
  }

  // Auto Play. Only active in Demo Mode.
  void toggleAutoPlay() {
    if (!demoMode) return;

    if (autoPlay) {
      stopAutoPlay();
    } else {
      startAutoPlay();
    }
  }

  void startAutoPlay() {
    if (!demoMode) return;

    autoPlay = true;
    _autoPlayTimer?.cancel();

    _autoPlayTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (!demoMode || !autoPlay) return;

        heading += 8;

        if (heading >= 360) {
          heading -= 360;
        }

        _lastHeading = heading;
        notifyListeners();
      },
    );

    notifyListeners();
  }

  void stopAutoPlay() {
    autoPlay = false;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;

    notifyListeners();
  }

  void setCoordinates(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

  void reset() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;

    demoMode = false;
    autoPlay = false;
    heading = 0.0;
    _lastHeading = 0.0;

    latitude = 28.6139;
    longitude = 77.2090;

    notifyListeners();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();

    super.dispose();
  }
}
