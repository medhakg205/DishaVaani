import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  static const _key = 'device_id';
  static String? _cachedId;

  static Future<String> getId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }

    _cachedId = id;
    return id;
  }
}