#!/usr/bin/env python3
"""Continuous sync daemon for Apple Notes export.

Runs the exporter and transcriber on a configurable interval.

Usage:
    python3 watch.py                    # Run with interval from .env
    python3 watch.py --interval 60      # Run every 60 seconds
    python3 watch.py --once             # Run once and exit
"""

import argparse
import logging
import signal
import subprocess
import sys
import time
from pathlib import Path

from notes_export import load_config

SCRIPT_DIR = Path(__file__).resolve().parent
LOG_PATH = SCRIPT_DIR / ".sync.log"


def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(LOG_PATH),
            logging.StreamHandler(sys.stdout),
        ],
    )
    return logging.getLogger("watch")


def run_export(folders=None, all_folders=False):
    cmd = [sys.executable, str(SCRIPT_DIR / "notes_export.py"), "export"]
    if all_folders:
        cmd.append("--all")
    elif folders:
        cmd.extend(["--folders", ",".join(folders)])
    else:
        cmd.append("--all")

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    return result.stdout, result.stderr, result.returncode


def run_transcribe():
    cmd = [sys.executable, str(SCRIPT_DIR / "transcribe.py")]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)
    return result.stdout, result.stderr, result.returncode


def sync_cycle(logger, folders=None, all_folders=True, transcribe=True):
    """Run one complete sync cycle: export + transcribe."""
    logger.info("Starting sync cycle")

    logger.info("Running export...")
    stdout, stderr, rc = run_export(folders, all_folders)
    if rc == 0:
        for line in stdout.strip().split("\n")[-3:]:
            logger.info(f"  export: {line.strip()}")
    else:
        logger.error(f"Export failed (rc={rc}): {stderr}")

    if transcribe:
        logger.info("Running transcription...")
        stdout, stderr, rc = run_transcribe()
        if rc == 0:
            for line in stdout.strip().split("\n")[-3:]:
                logger.info(f"  transcribe: {line.strip()}")
        else:
            logger.error(f"Transcription failed (rc={rc}): {stderr}")

    logger.info("Sync cycle complete")


def main():
    parser = argparse.ArgumentParser(description="Continuous Apple Notes sync daemon")
    parser.add_argument("--interval", type=int, default=None,
                        help="Sync interval in seconds (default from .env)")
    parser.add_argument("--once", action="store_true", help="Run once and exit")
    parser.add_argument("--no-transcribe", action="store_true",
                        help="Skip audio transcription")
    parser.add_argument("--folders", type=str, help="Comma-separated folder names")
    args = parser.parse_args()

    cfg = load_config()
    interval = args.interval or cfg.get("watch_interval_seconds", 300)
    logger = setup_logging()

    folders = args.folders.split(",") if args.folders else None
    transcribe = not args.no_transcribe

    running = True

    def stop_handler(signum, frame):
        nonlocal running
        logger.info(f"Received signal {signum}, stopping...")
        running = False

    signal.signal(signal.SIGINT, stop_handler)
    signal.signal(signal.SIGTERM, stop_handler)

    if args.once:
        sync_cycle(logger, folders, all_folders=(folders is None), transcribe=transcribe)
        return

    logger.info(f"Starting watch mode (interval={interval}s)")
    logger.info(f"Log file: {LOG_PATH}")

    while running:
        try:
            sync_cycle(logger, folders, all_folders=(folders is None), transcribe=transcribe)
        except Exception as e:
            logger.error(f"Sync cycle error: {e}")

        if not running:
            break

        logger.info(f"Sleeping {interval}s until next cycle...")
        for _ in range(interval):
            if not running:
                break
            time.sleep(1)

    logger.info("Watch daemon stopped")


if __name__ == "__main__":
    main()
