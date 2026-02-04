#!/bin/bash

# Watch debs-to-repack and auto repack + push to repo

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WATCH_DIR="$REPO_DIR/debs-to-repack"
LOG_FILE="$REPO_DIR/.repack-watch.log"

mkdir -p "$WATCH_DIR" "$WATCH_DIR/.processed" "$WATCH_DIR/.failed"

if ! command -v fswatch >/dev/null 2>&1; then
  echo "❌ 缺少 fswatch，请先安装：brew install fswatch" | tee -a "$LOG_FILE"
  exit 1
fi

EXCLUDE_PATTERNS="\\.git|\\.processed|\\.failed|\\.DS_Store"

is_stable_file() {
  local f="$1"
  local s1 s2
  s1=$(stat -f%z "$f" 2>/dev/null || echo 0)
  sleep 1
  s2=$(stat -f%z "$f" 2>/dev/null || echo 0)
  [ "$s1" -eq "$s2" ]
}

process_deb() {
  local DEB_PATH="$1"
  local DEB_NAME
  DEB_NAME=$(basename "$DEB_PATH")
  local TIMESTAMP
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

  echo "[$TIMESTAMP] 🔍 检测到新deb: $DEB_NAME" | tee -a "$LOG_FILE"

  if ! is_stable_file "$DEB_PATH"; then
    echo "[$TIMESTAMP] ⏳ 文件仍在写入，稍后再试" | tee -a "$LOG_FILE"
    return 0
  fi

  # 先同步远端，避免 push 失败
  if ! (cd "$REPO_DIR" && git pull --rebase origin main >> "$LOG_FILE" 2>&1); then
    echo "[$TIMESTAMP] ❌ git pull --rebase 失败，跳过本次处理" | tee -a "$LOG_FILE"
    return 1
  fi

  if (cd "$REPO_DIR" && ./repack-deb.sh "$DEB_PATH" >> "$LOG_FILE" 2>&1); then
    echo "[$TIMESTAMP] ✅ 打包并推送成功" | tee -a "$LOG_FILE"
    mv "$DEB_PATH" "$WATCH_DIR/.processed/$DEB_NAME" 2>/dev/null || true
  else
    echo "[$TIMESTAMP] ❌ 打包或推送失败，已移至 .failed" | tee -a "$LOG_FILE"
    mv "$DEB_PATH" "$WATCH_DIR/.failed/$DEB_NAME" 2>/dev/null || true
  fi

  echo "[$TIMESTAMP] ---" | tee -a "$LOG_FILE"
}

echo "🚀 开始监听 debs-to-repack..." | tee -a "$LOG_FILE"
echo "📁 监听目录: $WATCH_DIR" | tee -a "$LOG_FILE"
echo "📝 日志文件: $LOG_FILE" | tee -a "$LOG_FILE"
echo "⏸  按 Ctrl+C 停止监听" | tee -a "$LOG_FILE"
echo "---" | tee -a "$LOG_FILE"

fswatch --recursive \
  --exclude="$EXCLUDE_PATTERNS" \
  --batch-marker \
  --latency 2 \
  "$WATCH_DIR" | while read -r line; do

  if [ "$line" = "BreakMarker" ]; then
    for deb in "$WATCH_DIR"/*.deb; do
      if [ -f "$deb" ]; then
        process_deb "$deb"
      fi
    done
  fi
done
