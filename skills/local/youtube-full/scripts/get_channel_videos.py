#!/usr/bin/env python3
"""List recent videos from a channel using search.list with channelId."""

import argparse
import json
import os
import sys
import time
from typing import Any, Dict

import requests

API_URL = "https://www.googleapis.com/youtube/v3/search"


def load_api_key(explicit: str | None = None) -> str:
    key = explicit or os.getenv("YOUTUBE_API_KEY")
    if not key:
        raise SystemExit("Missing API key. Set YOUTUBE_API_KEY or pass --api-key.")
    return key


def main() -> None:
    parser = argparse.ArgumentParser(description="List recent videos for a channel")
    parser.add_argument("--channel-id", required=True, help="Channel ID (starts with UC)")
    parser.add_argument("--max-results", type=int, default=25, help="Results per page (1-50)")
    parser.add_argument("--max-pages", type=int, help="Limit number of pages to fetch")
    parser.add_argument(
        "--order",
        choices=["date", "rating", "title", "videoCount", "viewCount"],
        default="date",
        help="Ordering (default=date)",
    )
    parser.add_argument("--published-after", help="ISO timestamp filter")
    parser.add_argument("--api-key", help="Override YOUTUBE_API_KEY env")
    parser.add_argument("--throttle", type=float, default=0.0, help="Seconds to wait between requests")
    args = parser.parse_args()

    api_key = load_api_key(args.api_key)

    params: Dict[str, Any] = {
        "key": api_key,
        "part": "snippet",
        "channelId": args.channel_id,
        "type": "video",
        "order": args.order,
        "maxResults": max(1, min(args.max_results, 50)),
    }
    if args.published_after:
        params["publishedAfter"] = args.published_after

    all_items = []
    page = 0
    next_token = None

    while True:
        page += 1
        resp = requests.get(API_URL, params=params, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        all_items.extend(data.get("items", []))
        next_token = data.get("nextPageToken")

        if not next_token or (args.max_pages and page >= args.max_pages):
            break
        params["pageToken"] = next_token
        if args.throttle:
            time.sleep(args.throttle)

    json.dump(
        {
            "channelId": args.channel_id,
            "totalItems": len(all_items),
            "items": all_items,
            "nextPageToken": next_token,
        },
        sys.stdout,
        ensure_ascii=False,
        indent=2,
    )
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
