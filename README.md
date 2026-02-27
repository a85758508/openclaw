# OpenClaw

给逸珩的睡前故事系统 — AI 生成故事 + 用爸爸妈妈的声音朗读。

## 项目结构

```
├── bedtime_story_app/   # Flutter 移动端 App
├── bedtime-story/       # Python 故事生成脚本（ElevenLabs 语音合成）
├── skills/              # 自动化技能（YouTube 频道监控等）
├── memory/              # 工作记忆与日志
├── AGENTS.md            # 工作空间规范
└── HEARTBEAT.md         # 每日定时任务
```

## Bedtime Story App (Flutter)

一个为逸珩量身打造的睡前故事 App：

- **AI 故事生成**：GPT-4o-mini 根据主题创作温柔的中文睡前故事
- **语音朗读**：OpenAI TTS 将故事转为语音，支持一键播放
- **声音克隆**：录制家长声音，用爸爸妈妈的声音讲故事（OpenAI Custom Voice API）
- **三层 Fallback**：自定义声音 → nova + 温柔语调指令 → tts-1 兜底
- **故事管理**：AI 生成或手动创作，本地持久化存储

### 运行

```bash
cd bedtime_story_app
flutter pub get
flutter run --dart-define=OPENAI_API_KEY=your_key_here
```

## Bedtime Story Generator (Python)

命令行版故事生成器，支持 ElevenLabs 语音合成：

```bash
cd bedtime-story
pip install -r requirements.txt
python generate.py --text "小兔子去月球"
```

## 技术栈

- **移动端**：Flutter / Dart、Provider、just_audio、record
- **AI**：OpenAI GPT-4o-mini、OpenAI TTS (gpt-4o-mini-tts)、ElevenLabs
- **自动化**：Python、YouTube Data API
