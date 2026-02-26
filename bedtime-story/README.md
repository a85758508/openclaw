# Bedtime Story Generator - 睡前故事生成器

为你 2 岁半的孩子定制：用你的声音讲睡前故事。

## 快速启动

### 1. 声音克隆（ElevenLabs）
1. 注册 https://elevenlabs.io
2. 订阅最便宜套餐（$5/月）
3. 上传你的声音录音（3-5 分钟，清晰朗读）
4. 获取 Voice ID（在 Voice Lab 里）
5. 获取 API Key（Profile → API Keys）

### 2. 配置
```bash
cp .env.example .env
# 编辑 .env 填入：
# - ELEVENLABS_API_KEY
# - ELEVENLABS_VOICE_ID
# - CHILD_NAME（你孩子的名字/小名）
```

### 3. 运行
```bash
# 安装依赖
pip3 install -r requirements.txt

# 生成一个故事（文本 → 音频）
python3 generate.py --text "从前有一只小兔子..." --output story_001.mp3

# 或者用预设故事
python3 generate.py --preset rabbit --output story_001.mp3

# 或者让 AI 自动生成故事
python3 generate.py --auto --output story_001.mp3
```

## 文件结构
```
bedtime-story/
├── README.md
├── .env.example
├── requirements.txt
├── generate.py          # 主脚本
├── stories/             # 预设故事模板
│   ├── rabbit.md
│   ├── bear.md
│   └── stars.md
├── output/              # 生成的音频
└── voice_sample.mp3     # 你的声音样本（自己录）
```

## 给 2 岁半孩子的故事特点
- 时长：2-5 分钟（约 200-500 字）
- 句式：简单、重复
- 节奏：慢、舒缓
- 内容：动物、日常、温暖结局
- 可以加入孩子名字增加亲近感

## 下一步扩展
- [ ] Telegram Bot 集成（发送 /story 自动生成）
- [ ] 网页播放器（孩子自己点）
- [ ] 定时播放（睡前自动）
- [ ] 本地 TTS 迁移（XTTS，无月费）
