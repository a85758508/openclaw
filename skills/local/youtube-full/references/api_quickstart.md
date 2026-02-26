# YouTube Data API 快速指南

> 仅保留执行任务所需的字段/端点，详细 schema 请参考官方文档：<https://developers.google.com/youtube/v3/docs>

## 常用端点

| 端点 | 用途 | 关键参数 | 备注 |
|------|------|----------|------|
| `search.list` | 搜索视频/频道/播放列表 | `part=snippet`, `type=video|channel|playlist`, `q`, `maxResults`, `order` | 每次调用配额 100 |
| `videos.list` | 视频详情 (统计/内容/状态) | `part=snippet,contentDetails,statistics`, `id` | 每次调用配额 1 |
| `channels.list` | 频道详情 | `part=snippet,statistics,contentDetails`, `id` | `contentDetails.relatedPlaylists.uploads` 可拿频道上传播放列表 |
| `playlistItems.list` | 播放列表条目 | `part=snippet,contentDetails`, `playlistId`, `pageToken` | 每次调用配额 1 |

## API Key 传递方式

- 通过查询参数 `key=YOUR_KEY`
- 或在脚本里读取环境变量 `YOUTUBE_API_KEY`

## 分页说明

- `maxResults` 最多 50。
- 响应包含 `nextPageToken`，继续调用时带上即可。
- 本技能脚本默认会自动循环直到拿完所有页（可用 `--max-pages` 限制）。

## Transcript 抓取

- 使用 `youtube-transcript-api` 库（无需官方 API）
- 常用参数：
  - `languages=['zh-Hans','zh','en']`
  - `translate='en'` （若想强制翻译）
- 异常：`TranscriptsDisabled`, `NoTranscriptFound`

## 配额提示

- 每个项目默认每天 10,000 单位。
- 搜索 (`search.list`) 消耗 100 单位，视频/频道/播放列表详情仅 1 单位。
- 监控配额：GCP 控制台 -> APIs & Services -> Dashboard -> Quotas。

## 响应字段速查

### `videos.list`

```json
{
  "id": "VIDEO_ID",
  "snippet": {
    "title": "...",
    "description": "...",
    "channelTitle": "...",
    "publishedAt": "..."
  },
  "contentDetails": {
    "duration": "PT5M10S",
    "definition": "hd"
  },
  "statistics": {
    "viewCount": "12345",
    "likeCount": "678",
    "commentCount": "9"
  }
}
```

### `playlistItems.list`

```json
{
  "snippet": {
    "title": "...",
    "resourceId": {
      "videoId": "VIDEO_ID"
    }
  },
  "contentDetails": {
    "videoPublishedAt": "..."
  }
}
```
