#!/usr/bin/env python3
"""
Bedtime Story Telegram Bot
用 Telegram 发送 /story 命令，自动生成并发送故事音频

用法:
    python3 telegram_bot.py
"""

import os
import sys
import asyncio
from pathlib import Path
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
ELEVENLABS_VOICE_ID = os.getenv("ELEVENLABS_VOICE_ID")
CHILD_NAME = os.getenv("CHILD_NAME", "宝宝")

if not TELEGRAM_BOT_TOKEN:
    print("❌ 缺少 TELEGRAM_BOT_TOKEN")
    print("请在 .env 中设置 Telegram Bot Token")
    print("提示：可以用现有的 OpenClaw Telegram Bot Token")
    sys.exit(1)

# 导入 generate.py 的函数
sys.path.insert(0, str(Path(__file__).parent))
from generate import generate_story_text, tts_elevenlabs, list_presets

# Telegram
import requests

BOT_API = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"


def send_message(chat_id, text):
    """发送文本消息"""
    url = f"{BOT_API}/sendMessage"
    data = {"chat_id": chat_id, "text": text}
    requests.post(url, json=data)


def send_audio(chat_id, audio_path, caption=None):
    """发送音频文件"""
    url = f"{BOT_API}/sendAudio"
    with open(audio_path, "rb") as f:
        files = {"audio": f}
        data = {"chat_id": chat_id}
        if caption:
            data["caption"] = caption
        requests.post(url, data=data, files=files)


def get_updates(offset=0):
    """获取更新"""
    url = f"{BOT_API}/getUpdates"
    params = {"offset": offset, "timeout": 30}
    response = requests.get(url, params=params, timeout=35)
    return response.json().get("result", [])


async def run_bot():
    """运行 Bot"""
    print("🤖 Bedtime Story Bot 启动中...")
    print(f"👶 孩子名字：{CHILD_NAME}")
    print(f"🎙️ ElevenLabs Voice ID: {ELEVENLABS_VOICE_ID[:8]}...")
    print("-" * 40)
    
    last_update_id = 0
    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(exist_ok=True)
    
    while True:
        try:
            updates = get_updates(last_update_id + 1)
            
            for update in updates:
                last_update_id = update["update_id"]
                
                # 检查是否有消息
                if "message" not in update:
                    continue
                
                message = update["message"]
                chat_id = message["chat_id"]
                text = message.get("text", "").strip()
                
                # 检查命令
                if text == "/story":
                    send_message(chat_id, f"📖 好的，正在给{CHILD_NAME}生成故事...")
                    
                    # 生成故事
                    story_text = generate_story_text(auto=True, child_name=CHILD_NAME)
                    output_path = output_dir / f"story_{last_update_id}.mp3"
                    
                    # 生成音频
                    tts_elevenlabs(story_text, str(output_path))
                    
                    # 发送音频
                    send_audio(chat_id, str(output_path), caption=f"🌙 晚安，{CHILD_NAME}")
                    
                    # 清理文件（可选）
                    # output_path.unlink()
                
                elif text == "/story rabbit":
                    send_message(chat_id, f"🐰 好的，正在生成《小兔子》故事...")
                    story_text = generate_story_text(preset="rabbit", child_name=CHILD_NAME)
                    output_path = output_dir / f"story_rabbit_{last_update_id}.mp3"
                    tts_elevenlabs(story_text, str(output_path))
                    send_audio(chat_id, str(output_path), caption=f"🐰 小兔子找星星 · {CHILD_NAME}")
                
                elif text == "/story bear":
                    send_message(chat_id, f"🐻 好的，正在生成《小熊》故事...")
                    story_text = generate_story_text(preset="bear", child_name=CHILD_NAME)
                    output_path = output_dir / f"story_bear_{last_update_id}.mp3"
                    tts_elevenlabs(story_text, str(output_path))
                    send_audio(chat_id, str(output_path), caption=f"🐻 小熊的蜂蜜罐 · {CHILD_NAME}")
                
                elif text == "/story stars":
                    send_message(chat_id, f"🌙 好的，正在生成《月亮婆婆》故事...")
                    story_text = generate_story_text(preset="stars", child_name=CHILD_NAME)
                    output_path = output_dir / f"story_stars_{last_update_id}.mp3"
                    tts_elevenlabs(story_text, str(output_path))
                    send_audio(chat_id, str(output_path), caption=f"🌙 月亮婆婆讲故事 · {CHILD_NAME}")
                
                elif text == "/help":
                    help_text = f"""📚 睡前故事 Bot 帮助

可用命令:
/story - 随机生成一个故事
/story rabbit - 小兔子找星星
/story bear - 小熊的蜂蜜罐
/story stars - 月亮婆婆讲故事
/help - 显示帮助

生成的故事会用你的声音朗读哦～"""
                    send_message(chat_id, help_text)
                
                elif text == "/start":
                    send_message(chat_id, f"👋 欢迎使用睡前故事 Bot！\n\n我会用你的声音给{CHILD_NAME}讲故事哦～\n\n发送 /help 查看可用命令")
            
            await asyncio.sleep(1)
            
        except Exception as e:
            print(f"❌ 错误：{e}")
            await asyncio.sleep(5)


if __name__ == "__main__":
    asyncio.run(run_bot())
