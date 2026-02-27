import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/voice_service.dart';

enum VoiceSetupStatus {
  idle,
  recording,
  uploading,
  creatingVoice,
  done,
  error,
}

class VoiceProvider extends ChangeNotifier {
  static const _voiceIdKey = 'custom_voice_id';

  final VoiceService _voiceService;

  VoiceSetupStatus _status = VoiceSetupStatus.idle;
  String _errorMessage = '';
  String? _customVoiceId;

  VoiceProvider({required VoiceService voiceService})
      : _voiceService = voiceService;

  VoiceSetupStatus get status => _status;
  String get errorMessage => _errorMessage;
  String? get customVoiceId => _customVoiceId;
  bool get hasCustomVoice => _customVoiceId != null;

  /// Load persisted voice_id from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customVoiceId = prefs.getString(_voiceIdKey);
    notifyListeners();
  }

  /// Full voice setup flow: upload consent → create voice → persist.
  Future<void> setupVoice({
    required String consentPath,
    required String samplePath,
    String name = 'bedtime_parent_voice',
  }) async {
    _status = VoiceSetupStatus.uploading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Step 1: Upload consent recording
      final consentId = await _voiceService.uploadConsent(consentPath);

      // Step 2: Create voice with sample
      _status = VoiceSetupStatus.creatingVoice;
      notifyListeners();

      final voiceId = await _voiceService.createVoice(
        consentId: consentId,
        samplePath: samplePath,
        name: name,
      );

      // Step 3: Persist
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_voiceIdKey, voiceId);
      _customVoiceId = voiceId;

      _status = VoiceSetupStatus.done;
      notifyListeners();
    } catch (e) {
      _status = VoiceSetupStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear the stored custom voice.
  Future<void> clearVoice() async {
    if (_customVoiceId != null) {
      // Best-effort delete on server
      try {
        await _voiceService.deleteVoice(_customVoiceId!);
      } catch (_) {
        // ignore
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_voiceIdKey);
    _customVoiceId = null;
    _status = VoiceSetupStatus.idle;
    notifyListeners();
  }

  void resetStatus() {
    _status = VoiceSetupStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
