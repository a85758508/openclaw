#!/usr/bin/env python3
"""Fetch video metadata (snippet/contentDetails/statistics) for one or more IDs."""

import argparse
import json
import os
import sys
from typing import List

import requests

API_URL = "https://www.googleapis.com/youtube/v3/videos"


def load_api_key(explicit: str | None = None) -> str:
    key = explicit or os.getenv("YOUTUBE_API_KEY")
    if not key:
        raise SystemExit("Missing API key. Set YOUTUBE_API_KEY or pass --api-key.")
    return key


def chunks(seq: List[str], size: int) -> List[List[str]]:
    return [seq[i : i + size] for i in range(0, len(seq), size)]


def main() -> None:
    parser = argparse.ArgumentParser(description="Get video details via Data API v3")
    parser.add_argument("--ids", required=True, help="Comma-separated video IDs")
    parser.add_argument(
        "--parts",
        default="snippet,contentDetails,statistics",
        help="Comma-separated part list (default: snippet,contentDetails,statistics)",
    )
    parser.add_argument("--api-key", help="Override YOUTUBE_API_KEY env")
    args = parser.parse_args()

    api_key = load_api_key(args.api_key)
    ids = [vid.strip() for vid in args.ids.split(",") if vid.strip()]
    if not ids:
        raise SystemExit("No valid video IDs provided.")

    collected = []
    for batch in chunks(ids, 50):  # API allows up to 50 IDs per call
        params = {
            "key": api_key,
            "part": args.parts,
            "id": ",".join(batch),
            "maxResults": len(batch),
        }
        resp = requests.get(API_URL, params=params, timeout=30)
        resp.raise_for_status()
        collected.extend(resp.json().get("items", []))

    output = {
        "requested": ids,
        "retrieved": len(collected),
        "items": collected,
    }
    json.dump(output, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
