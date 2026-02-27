import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class OpenAIService {
  static const _baseUrl = 'https://api.openai.com/v1';
  // TODO: Move to --dart-define for production
  static const _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  /// Generate a bedtime story using GPT.
  /// Returns a map with 'title', 'subtitle', and 'content' keys.
  Future<Map<String, String>> generateStory(
    String prompt, {
    required String childName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': '你是一位温柔的睡前故事作家，专门为一个叫"$childName"的小朋友写故事。\n'
                '要求：\n'
                '- 用中文写作，语气温柔、舒缓\n'
                '- 使用短句子，适合朗读\n'
                '- 故事长度在300-500字之间\n'
                '- 故事结尾要温暖安心，引导入睡\n'
                '- 请返回 JSON 格式，包含三个字段：\n'
                '  - title: 故事标题（以"$childName"开头）\n'
                '  - subtitle: 一句话简介\n'
                '  - content: 故事正文',
          },
          {
            'role': 'user',
            'content': '请根据以下主题写一个睡前故事：$prompt',
          },
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.8,
        'max_tokens': 1500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('GPT API 调用失败 (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['choices'][0]['message']['content'] as String;
    final parsed = jsonDecode(text) as Map<String, dynamic>;

    return {
      'title': (parsed['title'] as String?) ?? '$childName的故事',
      'subtitle': (parsed['subtitle'] as String?) ?? '一个温柔的晚安故事',
      'content': parsed['content'] as String,
    };
  }

  /// Convert text to speech using OpenAI TTS and save as mp3.
  ///
  /// Two-tier fallback (used when ElevenLabs is unavailable):
  /// 1. nova + gpt-4o-mini-tts + instructions (good, tonal control)
  /// 2. nova + tts-1 (original baseline)
  Future<void> textToSpeech(
    String text,
    String outputPath, {
    String? instructions,
  }) async {
    // Tier 1: nova + gpt-4o-mini-tts + instructions
    if (instructions != null) {
      try {
        await _callTts(
          text,
          outputPath,
          model: 'gpt-4o-mini-tts',
          voice: 'nova',
          instructions: instructions,
        );
        return;
      } catch (_) {
        // fall through to tier 2
      }
    }

    // Tier 2: nova + tts-1 (baseline)
    await _callTts(text, outputPath, model: 'tts-1', voice: 'nova');
  }

  Future<void> _callTts(
    String text,
    String outputPath, {
    required String model,
    required String voice,
    String? instructions,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'input': text,
      'voice': voice,
      'response_format': 'mp3',
    };
    if (instructions != null) {
      body['instructions'] = instructions;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/audio/speech'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('TTS API 调用失败 (${response.statusCode}): ${response.body}');
    }

    final file = File(outputPath);
    await file.writeAsBytes(response.bodyBytes);
  }
}
