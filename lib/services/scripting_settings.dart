import 'package:flutter/foundation.dart';

class ScriptingSettings extends ChangeNotifier {
  static final ScriptingSettings _instance = ScriptingSettings._internal();
  factory ScriptingSettings() => _instance;
  ScriptingSettings._internal();

  bool _isDynamicScriptingEnabled = true; // Default ON

  bool get isDynamicScriptingEnabled => _isDynamicScriptingEnabled;

  void toggleDynamicScripting(bool value) {
    _isDynamicScriptingEnabled = value;
    notifyListeners();
  }
}