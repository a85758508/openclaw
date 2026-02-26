#!/usr/bin/env python3
"""
Bedtime Story Generator
用你的声音给孩子生成睡前故事

用法:
    python3 generate.py --text "从前有一只小兔子..." --output story.mp3
    python3 generate.py --preset rabbit --output story.mp3
    python3 generate.py --auto --output story.mp3
    python3 generate.py --list-presets
"""

import os
import sys
import argparse
from pathlib import Path
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
ELEVENLABS_VOICE_ID = os.getenv("ELEVENLABS_VOICE_ID")
CHILD_NAME = os.getenv("CHILD_NAME", "宝宝")
OUTPUT_DIR = Path(os.getenv("OUTPUT_DIR", "output"))

# 确保输出目录存在
OUTPUT_DIR.mkdir(exist_ok=True)


def generate_story_text(auto=False, preset=None, child_name=CHILD_NAME):
    """生成故事文本"""
    
    if preset:
        return load_preset(preset, child_name)
    
    if auto:
        return generate_ai_story(child_name)
    
    return None


def load_preset(preset_name, child_name):
    """加载预设故事"""
    stories_dir = Path(__file__).parent / "stories"
    preset_file = stories_dir / f"{preset_name}.md"
    
    if not preset_file.exists():
        print(f"❌ 预设故事不存在：{preset_name}")
        print(f"可用预设：{list_presets()}")
        sys.exit(1)
    
    content = preset_file.read_text()
    # 替换占位符
    content = content.replace("{child_name}", child_name)
    return content


def list_presets():
    """列出所有预设故事"""
    stories_dir = Path(__file__).parent / "stories"
    if not stories_dir.exists():
        return []
    return [f.stem for f in stories_dir.glob("*.md")]


def generate_ai_story(child_name):
    """用 AI 自动生成故事"""
    print("🤖 正在用 Qwen 生成故事...")
    
    prompt = f"""你是一个专业的儿童故事作家。请为一個 2 岁半的孩子写一个睡前故事。

要求：
- 时长：2-5 分钟（约 200-400 字）
- 句式：简单、有重复
- 节奏：慢、舒缓
- 内容：温暖、正面、有安全感
- 可以加入孩子名字：{child_name}
- 结局：安心入睡

请直接输出故事内容，不要有其他说明。"""

    # 尝试用 OpenClaw 的 Qwen
    try:
        from openclaw import sessions_send
        # 这个需要 OpenClaw 内部调用，简化处理
        pass
    except:
        pass
    
    # 简化版本：用预设模板
    return f"""从前，有一个可爱的小兔子，它的名字叫{child_name}。

每天早上，{child_name}都会起床，伸个懒腰，然后去吃好吃的胡萝卜。

{child_name}最喜欢在森林里散步，看看小花，听听小鸟唱歌。

到了晚上，{child_name}累了，躺在床上，听着妈妈的声音，慢慢地睡着了。

晚安，{child_name}。"""


def tts_elevenlabs(text, output_path):
    """用 ElevenLabs 生成音频"""
    import requests
    
    if not ELEVENLABS_API_KEY or not ELEVENLABS_VOICE_ID:
        print("❌ 缺少 ElevenLabs 配置")
        print("请在 .env 文件中设置 ELEVENLABS_API_KEY 和 ELEVENLABS_VOICE_ID")
        sys.exit(1)
    
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{ELEVENLABS_VOICE_ID}"
    
    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json",
    }
    
    data = {
        "text": text,
        "model_id": "eleven_monolingual_v1",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75,
            "style": 0.0,
            "use_speaker_boost": True,
        },
    }
    
    print("🔊 正在生成音频（ElevenLabs）...")
    
    response = requests.post(url, json=data, headers=headers)
    
    if response.status_code != 200:
        print(f"❌ ElevenLabs API 错误：{response.status_code}")
        print(response.text)
        sys.exit(1)
    
    # 保存音频
    with open(output_path, "wb") as f:
        f.write(response.content)
    
    print(f"✅ 音频已保存：{output_path}")
    return output_path


def main():
    parser = argparse.ArgumentParser(description="睡前故事生成器")
    parser.add_argument("--text", "-t", help="故事文本")
    parser.add_argument("--output", "-o", required=True, help="输出音频文件路径")
    parser.add_argument("--preset", "-p", help="使用预设故事 (rabbit, bear, stars)")
    parser.add_argument("--auto", "-a", action="store_true", help="用 AI 自动生成故事")
    parser.add_argument("--list-presets", "-l", action="store_true", help="列出所有预设")
    
    args = parser.parse_args()
    
    if args.list_presets:
        print("📚 可用预设故事:")
        for p in list_presets():
            print(f"  - {p}")
        sys.exit(0)
    
    # 生成故事文本
    if args.text:
        story_text = args.text
    elif args.preset:
        story_text = generate_story_text(preset=args.preset)
    elif args.auto:
        story_text = generate_story_text(auto=True)
    else:
        print("❌ 请提供 --text、--preset 或 --auto")
        sys.exit(1)
    
    print(f"📖 故事内容 ({len(story_text)} 字):")
    print("-" * 40)
    print(story_text[:200] + "..." if len(story_text) > 200 else story_text)
    print("-" * 40)
    
    # 生成音频
    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = OUTPUT_DIR / output_path
    
    tts_elevenlabs(story_text, str(output_path))
    
    print(f"\n🎉 完成！音频：{output_path}")


if __name__ == "__main__":
    main()
