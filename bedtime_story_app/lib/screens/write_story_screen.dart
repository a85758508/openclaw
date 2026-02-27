import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/story_provider.dart';
import 'story_player_screen.dart';

class WriteStoryScreen extends StatefulWidget {
  const WriteStoryScreen({super.key});

  @override
  State<WriteStoryScreen> createState() => _WriteStoryScreenState();
}

class _WriteStoryScreenState extends State<WriteStoryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  Future<void> _saveOnly() async {
    if (!_isValid) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<StoryProvider>();
      final story = await provider.saveManualStory(
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StoryPlayerScreen(storyId: story.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  Future<void> _saveAndGenerateAudio() async {
    if (!_isValid) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<StoryProvider>();
      final story = await provider.saveManualStory(
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      // Show progress dialog for TTS
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在生成语音...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

      final updated = await provider.generateAudioForStory(story.id);

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss dialog
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StoryPlayerScreen(storyId: updated.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Try to dismiss dialog if it's showing
      Navigator.of(context).pop();
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成语音失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('为宝宝写故事'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '故事标题',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '比如：宝宝和小兔子',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE8EEF7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE8EEF7)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '故事内容',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              onChanged: (_) => setState(() {}),
              maxLines: 10,
              decoration: InputDecoration(
                hintText: '从前从前，宝宝住在一个温暖的小房子里...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE8EEF7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE8EEF7)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: (_isValid && !_isSaving) ? _saveAndGenerateAudio : null,
              icon: const Icon(Icons.record_voice_over),
              label: const Text('保存并生成语音'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: (_isValid && !_isSaving) ? _saveOnly : null,
              icon: const Icon(Icons.save),
              label: const Text('仅保存文字'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
