import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/story_provider.dart';
import 'story_player_screen.dart';

class AiGenerateScreen extends StatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  State<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends State<AiGenerateScreen> {
  final _promptController = TextEditingController();
  bool _isGenerating = false;

  static const _quickThemes = [
    '挖掘机冒险',
    '小恐龙',
    '太空旅行',
    '森林动物',
    '海底世界',
    '消防车',
    '下雨天',
    '月亮上的兔子',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isGenerating = true);

    _showProgressDialog();

    try {
      final provider = context.read<StoryProvider>();
      final story = await provider.generateStory(prompt);

      if (!mounted) return;
      // Dismiss progress dialog
      Navigator.of(context).pop();
      // Navigate to player
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StoryPlayerScreen(storyId: story.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss dialog
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败：$e')),
      );
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Consumer<StoryProvider>(
        builder: (context, provider, _) {
          String message;
          switch (provider.status) {
            case StoryGenerationStatus.generatingText:
              message = '正在编写故事...';
            case StoryGenerationStatus.generatingAudio:
              message = '正在生成语音...';
            case StoryGenerationStatus.done:
              message = '完成！';
            case StoryGenerationStatus.error:
              message = '出错了';
            default:
              message = '准备中...';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.status != StoryGenerationStatus.error &&
                    provider.status != StoryGenerationStatus.done)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(),
                  ),
                if (provider.status == StoryGenerationStatus.done)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 48),
                  ),
                Text(message, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI 帮宝宝讲故事'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '宝宝今晚想听什么故事？',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '比如：宝宝和一只小猫在花园里探险...',
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
              '或者选一个主题：',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickThemes.map((theme) {
                return ActionChip(
                  label: Text(theme),
                  backgroundColor: const Color(0xFFB7F0D5),
                  onPressed: _isGenerating
                      ? null
                      : () {
                          _promptController.text = theme;
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('开始生成故事'),
              style: FilledButton.styleFrom(
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
