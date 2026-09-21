#!/usr/bin/env python3
import os
import sys
import time
import signal
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

# --- Configuration & Environment Defaults ---
SOURCE = os.getenv("SOURCE", "rtsp://@192.168.30.112:554/11")
DEVICE = os.getenv("DEVICE", "genbolt")
EXTRA_TIME = int(os.getenv("EXTRA_TIME", "200"))
DIR = Path(os.getenv("DIR", "/media/srv/videos/cam/"))
CODEC = os.getenv("CODEC", "mp4")
SNAPSHOT_OUTPUT_FOLDER = Path(os.getenv("SNAPSHOT_OUTPUT_FOLDER", "/media/cluster/common/home-assistant/www"))
SNAPSHOT_SLEEP_TIME = int(os.getenv("SNAPSHOT_SLEEP_TIME", "5"))

# Passed from Nomad job (defaults to local NFS path)
BASE_SEGMENT_DIR = Path(os.getenv("SEGMENT_DIR", "/media/cluster/camera/segments"))

# Explicit override if specified in Nomad env; otherwise auto-detected via ffprobe
TAG_V_OVERRIDE = os.getenv("TAG_V", "").strip()

now = datetime.now()
sleep_time = 30 if (0 <= now.hour < 6) else SNAPSHOT_SLEEP_TIME

d_str = now.strftime("%Y_%m_%d-%H")
f_str = now.strftime("%Y%m%d")

dest_dir = DIR / f_str
dest_dir.mkdir(parents=True, exist_ok=True)
SNAPSHOT_OUTPUT_FOLDER.mkdir(parents=True, exist_ok=True)

file_name = f"{d_str}-{DEVICE}.{CODEC}"
destination_file = dest_dir / file_name
local_temp_file = Path(f"./{file_name}")

output_snapshot = SNAPSHOT_OUTPUT_FOLDER / f"{DEVICE}-recent-snapshot.jpg"

# Construct hourly segment directory under BASE_SEGMENT_DIR
segment_dir = BASE_SEGMENT_DIR / f"{DEVICE}_{d_str}"
segment_dir.mkdir(parents=True, exist_ok=True)

shutdown_requested = False

def handle_signal(signum, frame):
    global shutdown_requested
    print("\n⚠️ Received termination signal (SIGTERM/SIGINT). Interrupting active recording...")
    shutdown_requested = True

signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)

def cleanup():
    print("🧹 Cleaning up temporary segment directory...")
    if segment_dir.exists():
        shutil.rmtree(segment_dir, ignore_errors=True)
    if local_temp_file.exists():
        local_temp_file.unlink(missing_ok=True)

def detect_codec(sample_segment_path):
    """Probes a segment file to detect video codec (h264 vs hevc/h265)."""
    try:
        cmd = [
            "ffprobe", "-v", "error",
            "-select_streams", "v:0",
            "-show_entries", "stream=codec_name",
            "-of", "default=noprint_wrappers=1:nokey=1",
            str(sample_segment_path)
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return res.stdout.strip().lower()
    except Exception as e:
        print(f"⚠️ ffprobe codec detection failed: {e}")
        return None

# --- Timing Calculation ---
minutes_remaining = 59 - now.minute
seconds_remaining = 60 - now.second
total_seconds = (minutes_remaining * 60) + seconds_remaining + EXTRA_TIME
target_end_time = time.time() + total_seconds

print(f"Recording {DEVICE} stream until end timestamp {int(target_end_time)}...")

segment_count = 0

try:
    # --- Step 1: Capture Loop ---
    while time.time() < target_end_time and not shutdown_requested:
        remaining_secs = int(target_end_time - time.time())
        if remaining_secs <= 5:
            print("✅ Time allocation complete.")
            break

        segment_count += 1
        current_segment = segment_dir / f"seg_{segment_count:03d}.ts"

        print(f"▶️ Running FFmpeg segment #{segment_count} ({remaining_secs} seconds remaining)...")

        ffmpeg_cmd = [
            "ffmpeg", "-hide_banner", "-loglevel", "warning",
            "-fflags", "+genpts+discardcorrupt",
            "-rtsp_transport", "tcp",
            "-timeout", "10000000",
            "-y", "-t", str(remaining_secs),
            "-i", SOURCE,
            "-map", "0:v", "-c:v", "copy",
            "-map", "0:a?", "-c:a", "aac",
            "-f", "mpegts", str(current_segment),
            "-map", "0:v", "-vf", f"fps=1/{sleep_time}", "-update", "1", str(output_snapshot)
        ]

        try:
            proc = subprocess.Popen(ffmpeg_cmd)
            while proc.poll() is None:
                if shutdown_requested:
                    proc.send_signal(signal.SIGINT)
                    try:
                        proc.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        proc.kill()
                    break
                time.sleep(1)
        except Exception as e:
            print(f"⚠️ Subprocess execution error: {e}")

        if time.time() < target_end_time and not shutdown_requested:
            print("⚠️ FFmpeg exited early. Retrying in 3 seconds...")
            time.sleep(3)

    # --- Step 2: Merge Segments ---
    segments = sorted(list(segment_dir.glob("seg_*.ts")))
    
    if segments:
        concat_list = segment_dir / "concat_list.txt"
        with open(concat_list, "w") as f:
            for seg in segments:
                f.write(f"file '{seg.absolute()}'\n")

        # Codec & Tag Detection Logic
        tag_v = TAG_V_OVERRIDE
        if not tag_v:
            detected_codec = detect_codec(segments[0])
            print(f"🔍 Detected video stream codec: {detected_codec}")
            if detected_codec in ["hevc", "h265"]:
                tag_v = "hvc1"

        print("📦 Merging segments into final MP4...")
        merge_cmd = [
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-f", "concat", "-safe", "0", "-i", str(concat_list),
            "-c", "copy"
        ]

        if tag_v:
            print(f"🏷️ Applying video tag: -tag:v {tag_v}")
            merge_cmd.extend(["-tag:v", tag_v])

        merge_cmd.extend(["-movflags", "+faststart", str(local_temp_file)])

        res = subprocess.run(merge_cmd)
        
        if res.returncode == 0 and local_temp_file.exists():
            print(f"Copying {local_temp_file} to {destination_file}...")
            shutil.copy2(local_temp_file, destination_file)
            print("Done")
        else:
            print(f"❌ Error: FFmpeg failed to merge segments (exit code {res.returncode}).")
    else:
        print("⚠️ No recording segments were created.")

finally:
    cleanup()