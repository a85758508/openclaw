import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/story.dart';
import '../services/openai_service.dart';
import '../services/story_storage_service.dart';

enum StoryGenerationStatus {
  idle,
  generatingText,
  generatingAudio,
  done,
  error,
}

class StoryProvider extends ChangeNotifier {
  static const _ttsInstructions =
      '用温柔、舒缓的语气朗读，像爸爸妈妈在床边讲睡前故事。语速稍慢，句间稍停。';

  final OpenAIService _openAI;
  final StoryStorageService _storage;
  final _uuid = const Uuid();

  List<Story> _stories = [];
  StoryGenerationStatus _status = StoryGenerationStatus.idle;
  String _errorMessage = '';
  String? _customVoiceId;

  StoryProvider({
    required OpenAIService openAIService,
    required StoryStorageService storageService,
  })  : _openAI = openAIService,
        _storage = storageService;

  /// Called by ProxyProvider to sync voice_id from VoiceProvider.
  void updateVoiceId(String? voiceId) {
    _customVoiceId = voiceId;
  }

  List<Story> get stories => List.unmodifiable(_stories);
  StoryGenerationStatus get status => _status;
  String get errorMessage => _errorMessage;

  Story? get latestStory => _stories.isNotEmpty ? _stories.first : null;

  Future<void> loadStories() async {
    _stories = await _storage.loadStories();
    // Sort newest first
    _stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  /// Generate a story using AI: GPT for text, then TTS for audio.
  /// Returns the created Story on success.
  Future<Story> generateStory(String prompt) async {
    _status = StoryGenerationStatus.generatingText;
    _errorMessage = '';
    notifyListeners();

    try {
      // Step 1: Generate story text via GPT
      final result = await _openAI.generateStory(prompt);

      final storyId = _uuid.v4();
      final audioPath = await _storage.audioPathForStory(storyId);

      _status = StoryGenerationStatus.generatingAudio;
      notifyListeners();

      // Step 2: Generate audio via TTS (with custom voice if available)
      await _openAI.textToSpeech(
        result['content']!,
        audioPath,
        customVoiceId: _customVoiceId,
        instructions: _ttsInstructions,
      );

      // Step 3: Save story
      final story = Story(
        id: storyId,
        title: result['title']!,
        subtitle: result['subtitle']!,
        content: result['content']!,
        audioPath: audioPath,
        createdAt: DateTime.now(),
        isAiGenerated: true,
      );

      await _storage.addStory(story);
      _stories.insert(0, story);

      _status = StoryGenerationStatus.done;
      notifyListeners();
      return story;
    } catch (e) {
      _status = StoryGenerationStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Save a manually written story (text only).
  Future<Story> saveManualStory(String title, String content) async {
    final story = Story(
      id: _uuid.v4(),
      title: title,
      subtitle: '自己写的睡前故事',
      content: content,
      createdAt: DateTime.now(),
      isAiGenerated: false,
    );

    await _storage.addStory(story);
    _stories.insert(0, story);
    notifyListeners();
    return story;
  }

  /// Generate audio for a story that only has text.
  Future<Story> generateAudioForStory(String storyId) async {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index < 0) throw Exception('故事未找到');

    _status = StoryGenerationStatus.generatingAudio;
    notifyListeners();

    try {
      final story = _stories[index];
      final audioPath = await _storage.audioPathForStory(storyId);
      await _openAI.textToSpeech(
        story.content,
        audioPath,
        customVoiceId: _customVoiceId,
        instructions: _ttsInstructions,
      );

      final updated = story.copyWith(audioPath: audioPath);
      _stories[index] = updated;
      await _storage.updateStory(updated);

      _status = StoryGenerationStatus.done;
      notifyListeners();
      return updated;
    } catch (e) {
      _status = StoryGenerationStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void resetStatus() {
    _status = StoryGenerationStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
