import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _key = 'child_name';
  static const _defaultName = '宝宝';

  String _childName = _defaultName;

  String get childName => _childName;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _childName = prefs.getString(_key) ?? _defaultName;
    notifyListeners();
  }

  Future<void> setChildName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _childName) return;
    _childName = trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, trimmed);
  }
}
