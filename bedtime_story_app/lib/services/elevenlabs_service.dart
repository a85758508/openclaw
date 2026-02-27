import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';

class ElevenLabsService {
  static const _baseUrl = 'https://api.elevenlabs.io/v1';
  static const _apiKey = String.fromEnvironment(
    'ELEVENLABS_API_KEY',
    defaultValue: '',
  );
  static const _voiceId = String.fromEnvironment(
    'ELEVENLABS_VOICE_ID',
    defaultValue: '',
  );

  /// Whether ElevenLabs credentials are configured.
  bool get isAvailable => _apiKey.isNotEmpty && _voiceId.isNotEmpty;

  String get voiceId => _voiceId;

  /// Convert text to speech using ElevenLabs TTS and save as mp3.
  Future<void> textToSpeech(String text, String outputPath) async {
    if (!isAvailable) {
      throw Exception('ElevenLabs 凭证未配置');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/text-to-speech/$_voiceId'),
      headers: {
        'xi-api-key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.28,
          'similarity_boost': 0.92,
          'style': 0.35,
          'use_speaker_boost': true,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'ElevenLabs TTS 调用失败 (${response.statusCode}): ${response.body}',
      );
    }

    final file = File(outputPath);
    await file.writeAsBytes(response.bodyBytes);
  }
}
