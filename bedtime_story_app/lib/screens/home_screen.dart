import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/story.dart';
import '../providers/story_provider.dart';
import '../providers/voice_provider.dart';
import 'ai_generate_screen.dart';
import 'story_player_screen.dart';
import 'voice_setup_screen.dart';
import 'write_story_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text('给宝宝的睡前故事'),
        actions: [
          Consumer<VoiceProvider>(
            builder: (context, voiceProvider, _) {
              final active = voiceProvider.shouldUseCustomVoice;
              return IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VoiceSetupScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.mic,
                  color: active
                      ? const Color(0xFF4CAF50)
                      : Colors.grey,
                ),
                tooltip: active ? '已启用自定义声音' : '设置声音',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<StoryProvider>(
          builder: (context, provider, _) {
            final stories = provider.stories;
            final latest = provider.latestStory;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Today's story card or empty state
                if (latest != null)
                  _TodayStoryCard(
                    title: latest.title,
                    subtitle: latest.subtitle,
                    onPlay: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoryPlayerScreen(storyId: latest.id),
                        ),
                      );
                    },
                  )
                else
                  _EmptyStateCard(cs: cs),

                // Voice setup prompt (when not configured)
                Consumer<VoiceProvider>(
                  builder: (context, voiceProvider, _) {
                    if (voiceProvider.shouldUseCustomVoice) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VoiceSetupScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFFFCC02)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE0B2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.record_voice_over,
                                    color: Color(0xFFE65100), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '用爸爸妈妈的声音讲故事',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '录制声音后，故事就能用您自己的声音朗读',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.black38),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                const _SectionTitle('你想怎么讲？'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BigActionButton(
                        title: '帮宝宝讲新故事',
                        subtitle: 'AI 生成 + 一键播放',
                        color: const Color(0xFFB7F0D5),
                        icon: Icons.auto_awesome,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AiGenerateScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BigActionButton(
                        title: '我来为宝宝写故事',
                        subtitle: '输入关键词/情节',
                        color: const Color(0xFFFFD6A5),
                        icon: Icons.edit_note,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WriteStoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Story history
                if (stories.length > 1) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('以前的故事'),
                  const SizedBox(height: 10),
                  // Skip the first (latest) story since it's in the card above
                  ...stories.skip(1).map(
                        (story) => _StoryListTile(
                          story: story,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    StoryPlayerScreen(storyId: story.id),
                              ),
                            );
                          },
                        ),
                      ),
                ],

                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EEF7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.favorite, color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '提示：故事会尽量用柔和语气、短句子，适合临睡前听。',
                          style: TextStyle(height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyStateCard({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBDE0FE), Color(0xFFFFC8DD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.nightlight_round, size: 48),
          const SizedBox(height: 12),
          const Text(
            '还没有故事哦',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '点击下方按钮，为宝宝创建第一个睡前故事吧！',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}

class _TodayStoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPlay;

  const _TodayStoryCard({
    required this.title,
    required this.subtitle,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBDE0FE), Color(0xFFFFC8DD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '宝宝的今日故事',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onPlay,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('播放'),
          ),
        ],
      ),
    );
  }
}

class _StoryListTile extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;

  const _StoryListTile({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EEF7)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: story.isAiGenerated
                      ? const Color(0xFFB7F0D5)
                      : const Color(0xFFFFD6A5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  story.isAiGenerated ? Icons.auto_awesome : Icons.edit_note,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      story.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                story.audioPath != null
                    ? Icons.play_circle_outline
                    : Icons.text_snippet_outlined,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
