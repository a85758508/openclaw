#!/usr/bin/env python3
"""Fetch transcript for a given YouTube video using youtube-transcript-api."""

import argparse
import json
import sys
from typing import List

from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api.formatters import JSONFormatter


def main() -> None:
    parser = argparse.ArgumentParser(description="Get YouTube transcript")
    parser.add_argument("--video-id", required=True, help="Video ID")
    parser.add_argument(
        "--languages",
        default="zh-Hans,zh,en",
        help="Comma-separated preferred languages (default: zh-Hans,zh,en)",
    )
    parser.add_argument(
        "--translate",
        help="Target language code to request auto translation (experimental)",
    )
    parser.add_argument("--output", help="Optional file path to save transcript JSON")
    args = parser.parse_args()

    languages: List[str] = [lang.strip() for lang in args.languages.split(",") if lang.strip()]
    transcript = YouTubeTranscriptApi.get_transcript(
        args.video_id,
        languages=languages,
    )

    if args.translate:
        transcript = YouTubeTranscriptApi.translate_transcript(transcript, args.translate)

    formatter = JSONFormatter()
    json_text = formatter.format_transcript(transcript)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(json_text)
    else:
        sys.stdout.write(json_text + "\n")


if __name__ == "__main__":
    main()
