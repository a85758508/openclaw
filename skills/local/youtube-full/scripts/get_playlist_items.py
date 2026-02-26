#!/usr/bin/env python3
"""Fetch all items from a playlist (handles pagination)."""

import argparse
import json
import os
import sys
import time
from typing import Any, Dict, List

import requests

API_URL = "https://www.googleapis.com/youtube/v3/playlistItems"


def load_api_key(explicit: str | None = None) -> str:
    key = explicit or os.getenv("YOUTUBE_API_KEY")
    if not key:
        raise SystemExit("Missing API key. Set YOUTUBE_API_KEY or pass --api-key.")
    return key


def fetch_playlist(playlist_id: str, params: Dict[str, Any], throttle: float, max_pages: int | None) -> Dict[str, Any]:
    items: List[Dict[str, Any]] = []
    page = 0
    next_token = None

    while True:
        page += 1
        resp = requests.get(API_URL, params=params, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        items.extend(data.get("items", []))
        next_token = data.get("nextPageToken")

        if not next_token or (max_pages and page >= max_pages):
            break
        params["pageToken"] = next_token
        if throttle:
            time.sleep(throttle)

    return {
        "playlistId": playlist_id,
        "totalItems": len(items),
        "items": items,
        "nextPageToken": next_token,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="List items in a YouTube playlist")
    parser.add_argument("--playlist-id", required=True, help="Playlist ID (starts with PL/UU/RD...)")
    parser.add_argument("--max-results", type=int, default=50, help="Items per page (1-50)")
    parser.add_argument("--max-pages", type=int, help="Limit number of pages to fetch")
    parser.add_argument("--api-key", help="Override YOUTUBE_API_KEY env")
    parser.add_argument("--throttle", type=float, default=0.0)

    args = parser.parse_args()

    api_key = load_api_key(args.api_key)

    params: Dict[str, Any] = {
        "key": api_key,
        "part": "snippet,contentDetails",
        "playlistId": args.playlist_id,
        "maxResults": max(1, min(args.max_results, 50)),
    }

    result = fetch_playlist(args.playlist_id, params, args.throttle, args.max_pages)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
