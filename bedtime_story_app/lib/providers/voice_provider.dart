import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/elevenlabs_service.dart';

class VoiceProvider extends ChangeNotifier {
  static const _enabledKey = 'custom_voice_enabled';

  final ElevenLabsService _elevenlabs;

  bool _enabled = false;

  VoiceProvider({required ElevenLabsService elevenlabsService})
      : _elevenlabs = elevenlabsService;

  /// Whether the user has turned on custom voice.
  bool get enabled => _enabled;

  /// Whether ElevenLabs credentials are configured at all.
  bool get isAvailable => _elevenlabs.isAvailable;

  /// Whether custom voice should be used for TTS right now.
  bool get shouldUseCustomVoice => _enabled && isAvailable;

  /// Load persisted toggle from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    notifyListeners();
  }

  /// Toggle custom voice on/off and persist.
  Future<void> toggle() async {
    _enabled = !_enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, _enabled);
    notifyListeners();
  }

  /// Explicitly set enabled state.
  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, _enabled);
    notifyListeners();
  }
}
