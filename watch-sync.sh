#!/bin/bash

# 双向同步监听脚本

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$REPO_DIR/.deb-repo-sync.log"

echo "🔄 开始监听仓库变化..."
echo "📁 仓库目录: $REPO_DIR"
echo "📝 日志文件: $LOG_FILE"
echo "⏸  按 Ctrl+C 停止监听"
echo "---"

EXCLUDE_PATTERNS="\.git|node_modules|\.DS_Store|\.log|__pycache__|\.venv"

sync_to_github() {
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${TIMESTAMP}] 📤 检测到变化，同步到GitHub..." | tee -a "$LOG_FILE"
    
    cd "$REPO_DIR"
    
    if git pull origin main 2>&1 | tee -a "$LOG_FILE"; then
        echo "[${TIMESTAMP}] ✓ 已拉取最新更改" | tee -a "$LOG_FILE"
    fi
    
    git add . 2>&1 | tee -a "$LOG_FILE"
    
    if git diff-index --quiet HEAD --; then
        echo "[${TIMESTAMP}] ✓ 无新更改" | tee -a "$LOG_FILE"
        echo "[${TIMESTAMP}] ---" | tee -a "$LOG_FILE"
        return
    fi
    
    if git commit -m "🔄 DEB仓库自动同步 - $TIMESTAMP" 2>&1 | tee -a "$LOG_FILE"; then
        if git push origin main 2>&1 | tee -a "$LOG_FILE"; then
            echo "[${TIMESTAMP}] ✅ 同步成功！" | tee -a "$LOG_FILE"
        else
            echo "[${TIMESTAMP}] ❌ 推送失败" | tee -a "$LOG_FILE"
        fi
    fi
    
    echo "[${TIMESTAMP}] ---" | tee -a "$LOG_FILE"
}

fswatch --recursive \
    --exclude="$EXCLUDE_PATTERNS" \
    --batch-marker \
    --latency 2 \
    "$REPO_DIR" | while read line; do
    
    if [ "$line" = "BreakMarker" ]; then
        sync_to_github
    fi
done
