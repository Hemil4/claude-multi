#!/usr/bin/env python3
"""
claude-multi usage tracker hook

Runs as a Claude Code "Stop" hook. Reads the session transcript,
extracts real token usage from API responses, and accumulates
per-profile stats in ~/.claude-multi/usage.json.

Usage data comes directly from Anthropic API responses logged
in the session JSONL — these are real token counts, not estimates.
"""

import json
import sys
import os
import time
from pathlib import Path
from datetime import datetime, timezone

USAGE_DIR = Path.home() / ".claude-multi"
USAGE_FILE = USAGE_DIR / "usage.json"
WINDOW_SECONDS = 5 * 60 * 60  # 5-hour rolling window


def get_profile_name():
    """Detect which claude-multi profile is active."""
    config_dir = os.environ.get("CLAUDE_CONFIG_DIR", "")
    if not config_dir:
        return "default"
    # Extract profile name from ~/.claude-<name>/
    dirname = os.path.basename(config_dir.rstrip("/"))
    if dirname.startswith(".claude-"):
        return dirname[8:]  # remove ".claude-" prefix
    return dirname


def extract_usage_from_transcript(transcript_path):
    """Read the last few entries of the session JSONL to find usage data."""
    if not transcript_path or not os.path.exists(transcript_path):
        return None

    # Read last 50KB in binary mode to handle UTF-8 boundaries safely
    file_size = os.path.getsize(transcript_path)
    read_size = min(file_size, 50000)

    usage_entries = []

    try:
        with open(transcript_path, "rb") as f:
            if file_size > read_size:
                f.seek(file_size - read_size)

            data = f.read()

        # Decode with error tolerance — partial multi-byte chars at start are OK
        text = data.decode("utf-8", errors="ignore")
        lines = text.split("\n")

        # Skip first line if we seeked (might be partial)
        if file_size > read_size and lines:
            lines = lines[1:]

        for line in lines:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                msg = obj.get("message", {})
                if isinstance(msg, dict) and "usage" in msg:
                    usage = msg["usage"]
                    model = msg.get("model", "unknown")
                    timestamp = obj.get("timestamp", "")
                    usage_entries.append({
                        "input_tokens": usage.get("input_tokens", 0),
                        "output_tokens": usage.get("output_tokens", 0),
                        "cache_read_input_tokens": usage.get("cache_read_input_tokens", 0),
                        "cache_creation_input_tokens": usage.get("cache_creation_input_tokens", 0),
                        "model": model,
                        "timestamp": timestamp,
                        "recorded_at": time.time(),
                    })
            except (json.JSONDecodeError, KeyError):
                continue
    except (IOError, OSError):
        return None

    return usage_entries[-1] if usage_entries else None


def load_usage_data():
    """Load existing usage tracking data."""
    if USAGE_FILE.exists():
        try:
            with open(USAGE_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return {"profiles": {}, "version": 1}


def save_usage_data(data):
    """Save usage tracking data."""
    USAGE_DIR.mkdir(parents=True, exist_ok=True)
    with open(USAGE_FILE, "w") as f:
        json.dump(data, f, indent=2)


def prune_old_entries(entries):
    """Remove entries older than the 5-hour window."""
    cutoff = time.time() - WINDOW_SECONDS
    return [e for e in entries if e.get("recorded_at", 0) > cutoff]


def main():
    # Read hook input from stdin
    try:
        hook_input = json.load(sys.stdin)
    except (json.JSONDecodeError, IOError):
        sys.exit(0)

    transcript_path = hook_input.get("transcript_path", "")
    session_id = hook_input.get("session_id", "unknown")

    # Extract latest usage from transcript
    latest_usage = extract_usage_from_transcript(transcript_path)
    if not latest_usage:
        sys.exit(0)

    # Detect profile
    profile = get_profile_name()

    # Load, update, and save
    data = load_usage_data()

    if profile not in data["profiles"]:
        data["profiles"][profile] = {
            "entries": [],
            "total_input_tokens": 0,
            "total_output_tokens": 0,
            "total_cache_read": 0,
            "total_cache_creation": 0,
            "last_model": "",
            "last_updated": "",
            "message_count": 0,
        }

    profile_data = data["profiles"][profile]

    # Add new entry
    latest_usage["session_id"] = session_id
    profile_data["entries"].append(latest_usage)

    # Prune old entries (outside 5h window)
    profile_data["entries"] = prune_old_entries(profile_data["entries"])

    # Recalculate totals from active entries
    profile_data["total_input_tokens"] = sum(
        e.get("input_tokens", 0) for e in profile_data["entries"]
    )
    profile_data["total_output_tokens"] = sum(
        e.get("output_tokens", 0) for e in profile_data["entries"]
    )
    profile_data["total_cache_read"] = sum(
        e.get("cache_read_input_tokens", 0) for e in profile_data["entries"]
    )
    profile_data["total_cache_creation"] = sum(
        e.get("cache_creation_input_tokens", 0) for e in profile_data["entries"]
    )
    profile_data["message_count"] = len(profile_data["entries"])
    profile_data["last_model"] = latest_usage.get("model", "")
    profile_data["last_updated"] = datetime.now(timezone.utc).isoformat()

    # Calculate window reset time
    if profile_data["entries"]:
        oldest = min(e.get("recorded_at", time.time()) for e in profile_data["entries"])
        profile_data["window_resets_at"] = oldest + WINDOW_SECONDS
    else:
        profile_data["window_resets_at"] = time.time() + WINDOW_SECONDS

    data["profiles"][profile] = profile_data
    save_usage_data(data)


if __name__ == "__main__":
    main()
