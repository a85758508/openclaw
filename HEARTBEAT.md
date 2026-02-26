# HEARTBEAT.md

## 每日 12:00（新加坡时间）— YouTube 频道巡检
- 仅当本地时间在 11:50–12:10 之间时运行，其他时间 `HEARTBEAT_OK`。
- 频道列表：
  1. 财经观察站 — `UCrJ6Hj2P2KdAIID5qqFjE7g`
  2. 老李玩钱 — `UCo2gxyermsLBSCxFHvJs0Zg`
- 通用步骤：
  1. `cd skills/local/youtube-full && source .venv/bin/activate && source load_env.sh`
  2. 对每个频道运行：`python scripts/get_channel_videos.py --channel-id <ID> --max-results 5 --order date`
  3. 比对 `memory/projects.md` 中该频道的“最近记录视频”。若 API 返回的最新 videoId 不同，视为新视频。
  4. 新视频处理流程：
     - 详情：`python scripts/get_video_details.py --ids <videoId>`
     - 字幕：`python scripts/get_transcript.py --video-id <videoId> --languages zh-Hans,zh,en --output /tmp/<videoId>.json`
     - 摘要：阅读字幕/元数据，提炼关键信息、写成摘要（主聊天风格），末尾附上“预计完成时间已内含”。
     - 记录：更新 `memory/projects.md` 里对应频道的“最近记录视频 = <videoId>（YYYY-MM-DD）`”。必要时把摘要要点写进 `memory/YYYY-MM-DD.md`。
  5. 如果两个频道都无更新，则回复 `HEARTBEAT_OK`。
