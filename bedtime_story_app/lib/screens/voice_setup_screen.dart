import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../providers/voice_provider.dart';

class VoiceSetupScreen extends StatefulWidget {
  const VoiceSetupScreen({super.key});

  @override
  State<VoiceSetupScreen> createState() => _VoiceSetupScreenState();
}

class _VoiceSetupScreenState extends State<VoiceSetupScreen> {
  static const _consentPhrase =
      'I agree to the use of my voice for generating speech through OpenAI.';

  static const _sampleText =
      '逸珩，今天晚上我们来讲一个关于星星的故事。'
      '很久很久以前，有一颗小星星住在天上最高的地方。'
      '他每天晚上都会眨着眼睛，看着地上的小朋友们甜甜地睡着。';

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  int _currentStep = 0; // 0=consent, 1=sample, 2=upload
  bool _isRecording = false;
  String? _consentPath;
  String? _samplePath;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<String> _tempPath(String name) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$name.wav';
  }

  Future<void> _startRecording(String fileName) async {
    if (!await _recorder.hasPermission()) return;

    final path = await _tempPath(fileName);
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  Future<String?> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    return path;
  }

  Future<void> _playPreview(String path) async {
    await _player.setFilePath(path);
    _player.play();
  }

  Future<void> _handleUpload() async {
    if (_consentPath == null || _samplePath == null) return;

    final provider = context.read<VoiceProvider>();
    await provider.setupVoice(
      consentPath: _consentPath!,
      samplePath: _samplePath!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('设置声音'),
      ),
      body: SafeArea(
        child: Consumer<VoiceProvider>(
          builder: (context, provider, _) {
            // If already has voice, show management view
            if (provider.hasCustomVoice &&
                provider.status != VoiceSetupStatus.error) {
              return _VoiceManagementView(
                onClear: () => provider.clearVoice(),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stepper indicator
                  _StepIndicator(currentStep: _currentStep),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildStep(provider, cs),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep(VoiceProvider provider, ColorScheme cs) {
    switch (_currentStep) {
      case 0:
        return _ConsentStep(
          phrase: _consentPhrase,
          isRecording: _isRecording,
          hasRecording: _consentPath != null,
          onStartRecording: () => _startRecording('consent'),
          onStopRecording: () async {
            final path = await _stopRecording();
            if (path != null) setState(() => _consentPath = path);
          },
          onPlay: _consentPath != null
              ? () => _playPreview(_consentPath!)
              : null,
          onNext: _consentPath != null
              ? () => setState(() => _currentStep = 1)
              : null,
        );
      case 1:
        return _SampleStep(
          sampleText: _sampleText,
          isRecording: _isRecording,
          hasRecording: _samplePath != null,
          onStartRecording: () => _startRecording('voice_sample'),
          onStopRecording: () async {
            final path = await _stopRecording();
            if (path != null) setState(() => _samplePath = path);
          },
          onPlay: _samplePath != null
              ? () => _playPreview(_samplePath!)
              : null,
          onBack: () => setState(() => _currentStep = 0),
          onNext: _samplePath != null
              ? () {
                  setState(() => _currentStep = 2);
                  _handleUpload();
                }
              : null,
        );
      case 2:
        return _UploadStep(
          status: provider.status,
          errorMessage: provider.errorMessage,
          onRetry: () {
            provider.resetStatus();
            _handleUpload();
          },
          onDone: () => Navigator.of(context).pop(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Step indicator ──────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labels = ['同意录音', '声音样本', '上传创建'];

    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? cs.primary : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? cs.primary : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Step 1: Consent ─────────────────────────────────────────────

class _ConsentStep extends StatelessWidget {
  final String phrase;
  final bool isRecording;
  final bool hasRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback? onPlay;
  final VoidCallback? onNext;

  const _ConsentStep({
    required this.phrase,
    required this.isRecording,
    required this.hasRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    this.onPlay,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '第 1 步：朗读同意语句',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          '请大声朗读以下英文短语，OpenAI 要求此步骤以确认您同意使用您的声音。',
          style: TextStyle(height: 1.4),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD0DCEF)),
          ),
          child: Text(
            phrase,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
        const Spacer(),
        _RecordButton(
          isRecording: isRecording,
          hasRecording: hasRecording,
          onStart: onStartRecording,
          onStop: onStopRecording,
        ),
        if (hasRecording) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('试听'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onNext,
                  child: const Text('下一步'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Step 2: Voice sample ────────────────────────────────────────

class _SampleStep extends StatelessWidget {
  final String sampleText;
  final bool isRecording;
  final bool hasRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback? onPlay;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  const _SampleStep({
    required this.sampleText,
    required this.isRecording,
    required this.hasRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    this.onPlay,
    required this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '第 2 步：录制声音样本',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          '请用您正常讲故事的语气朗读以下文字（建议 15~30 秒）。',
          style: TextStyle(height: 1.4),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8DCCC)),
          ),
          child: Text(
            sampleText,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
        const Spacer(),
        _RecordButton(
          isRecording: isRecording,
          hasRecording: hasRecording,
          onStart: onStartRecording,
          onStop: onStopRecording,
        ),
        if (hasRecording) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('试听'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onNext,
                  child: const Text('上传创建'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: onBack,
          child: const Text('返回上一步'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Step 3: Upload ──────────────────────────────────────────────

class _UploadStep extends StatelessWidget {
  final VoiceSetupStatus status;
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  const _UploadStep({
    required this.status,
    required this.errorMessage,
    required this.onRetry,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (status == VoiceSetupStatus.uploading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('正在上传同意录音...', style: TextStyle(fontSize: 16)),
          ] else if (status == VoiceSetupStatus.creatingVoice) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('正在创建您的声音...', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '这可能需要几分钟',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ] else if (status == VoiceSetupStatus.done) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFB7F0D5),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.check, size: 44, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 20),
            const Text(
              '声音创建成功！',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('接下来生成的故事将使用您的声音朗读'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDone,
              child: const Text('完成'),
            ),
          ] else if (status == VoiceSetupStatus.error) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.error_outline, size: 44, color: cs.error),
            ),
            const SizedBox(height: 20),
            const Text(
              '创建失败',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onDone,
              child: const Text('暂不设置'),
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('准备中...'),
          ],
        ],
      ),
    );
  }
}

// ── Shared record button ────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final bool hasRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _RecordButton({
    required this.isRecording,
    required this.hasRecording,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: isRecording ? onStop : onStart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isRecording ? 80 : 72,
          height: isRecording ? 80 : 72,
          decoration: BoxDecoration(
            color: isRecording ? Colors.red : const Color(0xFF6EC6FF),
            borderRadius: BorderRadius.circular(isRecording ? 16 : 36),
            boxShadow: [
              BoxShadow(
                color: (isRecording ? Colors.red : const Color(0xFF6EC6FF))
                    .withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

// ── Voice management (when already set up) ──────────────────────

class _VoiceManagementView extends StatelessWidget {
  final VoidCallback onClear;
  const _VoiceManagementView({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFB7F0D5),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.record_voice_over,
                  size: 44, color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '已设置自定义声音',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '生成的故事将使用您的声音朗读',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('清除自定义声音？'),
                  content: const Text('清除后将恢复使用默认声音，您可以随时重新录制。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onClear();
                      },
                      child: const Text('清除'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('清除自定义声音'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
