import 'dart:convert';

import 'package:http/http.dart' as http;

class VoiceService {
  static const _baseUrl = 'https://api.openai.com/v1';
  static const _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// Upload a consent recording (user reading the required phrase).
  /// Returns the consent_id on success.
  Future<String> uploadConsent(String audioPath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/audio/voice_consents'),
    );
    request.headers['Authorization'] = 'Bearer $_apiKey';
    request.files.add(
      await http.MultipartFile.fromPath('file', audioPath),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        '上传同意录音失败 (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// Create a custom voice using a consent ID and a voice sample.
  /// Returns the voice_id on success.
  Future<String> createVoice({
    required String consentId,
    required String samplePath,
    required String name,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/audio/voices'),
    );
    request.headers['Authorization'] = 'Bearer $_apiKey';
    request.fields['consent_id'] = consentId;
    request.fields['name'] = name;
    request.files.add(
      await http.MultipartFile.fromPath('file', samplePath),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        '创建自定义声音失败 (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['voice_id'] as String;
  }

  /// Delete a custom voice (cleanup).
  Future<void> deleteVoice(String voiceId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/audio/voices/$voiceId'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      // Non-critical — log but don't throw
    }
  }
}
