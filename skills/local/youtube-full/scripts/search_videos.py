#!/usr/bin/env python3
"""Search YouTube videos / channels / playlists via Data API v3.

Usage:
    python search_videos.py --query "openclaw" --max-results 10 --type video
"""

import argparse
import json
import os
import sys
import time
from typing import Any, Dict, List

import requests

API_URL = "https://www.googleapis.com/youtube/v3/search"


def load_api_key(explicit: str | None = None) -> str:
    key = explicit or os.getenv("YOUTUBE_API_KEY")
    if not key:
        raise SystemExit("Missing API key. Set YOUTUBE_API_KEY or pass --api-key.")
    return key


def search(params: Dict[str, Any], max_pages: int | None = None, throttle: float = 0.0) -> Dict[str, Any]:
    items: List[Dict[str, Any]] = []
    page = 0
    next_token = None

    while True:
        page += 1
        response = requests.get(API_URL, params=params, timeout=30)
        response.raise_for_status()
        data = response.json()
        items.extend(data.get("items", []))
        next_token = data.get("nextPageToken")

        if not next_token:
            break
        if max_pages and page >= max_pages:
            break

        params["pageToken"] = next_token
        if throttle:
            time.sleep(throttle)

    return {
        "query": params.get("q"),
        "type": params.get("type"),
        "totalItems": len(items),
        "items": items,
        "nextPageToken": next_token,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Search YouTube via Data API v3")
    parser.add_argument("--query", "-q", required=True, help="Search keywords")
    parser.add_argument("--type", choices=["video", "channel", "playlist"], default="video")
    parser.add_argument("--max-results", type=int, default=20, help="Results per page (1-50)")
    parser.add_argument("--max-pages", type=int, help="Maximum number of pages to fetch")
    parser.add_argument("--order", choices=["relevance", "date", "rating", "title", "videoCount", "viewCount"], default="relevance")
    parser.add_argument("--published-after", help="ISO timestamp filter (e.g. 2024-01-01T00:00:00Z)")
    parser.add_argument("--channel-id", help="Restrict to specific channel")
    parser.add_argument("--api-key", help="Override YOUTUBE_API_KEY env")
    parser.add_argument("--throttle", type=float, default=0.0, help="Seconds to wait between pages")

    args = parser.parse_args()

    api_key = load_api_key(args.api_key)

    params = {
        "key": api_key,
        "part": "snippet",
        "q": args.query,
        "type": args.type,
        "maxResults": max(1, min(args.max_results, 50)),
        "order": args.order,
    }
    if args.published_after:
        params["publishedAfter"] = args.published_after
    if args.channel_id:
        params["channelId"] = args.channel_id

    result = search(params, max_pages=args.max_pages, throttle=args.throttle)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
