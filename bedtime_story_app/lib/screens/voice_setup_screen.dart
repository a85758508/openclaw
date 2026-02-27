import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/voice_provider.dart';
import '../services/elevenlabs_service.dart';

class VoiceSetupScreen extends StatefulWidget {
  const VoiceSetupScreen({super.key});

  @override
  State<VoiceSetupScreen> createState() => _VoiceSetupScreenState();
}

class _VoiceSetupScreenState extends State<VoiceSetupScreen> {
  final _player = AudioPlayer();
  bool _isPreviewing = false;
  String? _previewError;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    setState(() {
      _isPreviewing = true;
      _previewError = null;
    });

    try {
      final elevenlabs = context.read<ElevenLabsService>();
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_preview.mp3';

      await elevenlabs.textToSpeech(
        '宝宝，今天晚上我们来讲一个关于星星的故事。很久很久以前，有一颗小星星住在天上最高的地方。',
        path,
      );

      await _player.setFilePath(path);
      _player.play();
    } catch (e) {
      setState(() => _previewError = e.toString());
    } finally {
      setState(() => _isPreviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('声音设置'),
      ),
      body: SafeArea(
        child: Consumer<VoiceProvider>(
          builder: (context, voiceProvider, _) {
            if (!voiceProvider.isAvailable) {
              return _UnavailableView(cs: cs);
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Voice icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: voiceProvider.enabled
                            ? const Color(0xFFB7F0D5)
                            : const Color(0xFFE8EEF7),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.record_voice_over,
                        size: 44,
                        color: voiceProvider.enabled
                            ? const Color(0xFF2E7D32)
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    voiceProvider.enabled ? '已启用自定义声音' : '使用默认声音',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    voiceProvider.enabled
                        ? '故事将使用您克隆的声音朗读'
                        : '开启后，故事将使用您克隆的声音朗读',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 32),

                  // Toggle card
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            color: voiceProvider.enabled
                                ? const Color(0xFFB7F0D5)
                                : const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.mic,
                            color: voiceProvider.enabled
                                ? const Color(0xFF2E7D32)
                                : cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '用我的声音讲故事',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Switch(
                          value: voiceProvider.enabled,
                          onChanged: (_) => voiceProvider.toggle(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Preview button
                  if (voiceProvider.enabled)
                    FilledButton.icon(
                      onPressed: _isPreviewing ? null : _preview,
                      icon: _isPreviewing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isPreviewing ? '正在生成试听...' : '试听效果'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                  if (_previewError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _previewError!,
                      style: TextStyle(color: cs.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const Spacer(),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD0DCEF)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: cs.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '关闭后将恢复使用默认声音（OpenAI nova），您可以随时再次开启。',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  final ColorScheme cs;
  const _UnavailableView({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.mic_off, size: 44, color: cs.error),
            ),
            const SizedBox(height: 20),
            const Text(
              '声音克隆未配置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '请在启动 App 时通过 --dart-define 配置 '
              'ELEVENLABS_API_KEY 和 ELEVENLABS_VOICE_ID。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
