#!/bin/bash

# 监听dylib文件夹，自动打包和上传

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DYLIBS_DIR="$REPO_DIR/dylibs-to-pack"
LOG_FILE="$REPO_DIR/.deb-build.log"

mkdir -p "$DYLIBS_DIR"

echo "🚀 开始监听dylib文件夹..."
echo "📁 监听目录: $DYLIBS_DIR"
echo "📝 日志文件: $LOG_FILE"
echo "⏸  按 Ctrl+C 停止监听"
echo "---"

# 排除模式
EXCLUDE_PATTERNS="\.git|\.conf|__pycache__|\.DS_Store"

# 处理新dylib文件的函数
process_dylib() {
    local DYLIB_PATH="$1"
    local DYLIB_NAME=$(basename "$DYLIB_PATH" .dylib)
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    echo "[${TIMESTAMP}] 🔍 检测到新dylib文件: $DYLIB_NAME" | tee -a "$LOG_FILE"
    
    # 检查配置文件是否存在
    CONFIG_FILE="$REPO_DIR/deb-tools/${DYLIB_NAME}.conf"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[${TIMESTAMP}] ⚠️  缺少配置文件: $CONFIG_FILE" | tee -a "$LOG_FILE"
        echo "[${TIMESTAMP}] 💡 请先运行: python3 $REPO_DIR/config-builder.py" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 执行打包流程
    if cd "$REPO_DIR" && "./full-process.sh" "$DYLIB_PATH" "自动打包: $DYLIB_NAME" >> "$LOG_FILE" 2>&1; then
        echo "[${TIMESTAMP}] ✅ 打包成功！" | tee -a "$LOG_FILE"
        
        # 移动dylib到已处理文件夹
        mv "$DYLIB_PATH" "$DYLIBS_DIR/.processed/${DYLIB_NAME}.dylib" 2>/dev/null || true
    else
        echo "[${TIMESTAMP}] ❌ 打包失败，请查看日志" | tee -a "$LOG_FILE"
    fi
    
    echo "[${TIMESTAMP}] ---" | tee -a "$LOG_FILE"
}

# 创建已处理文件夹
mkdir -p "$DYLIBS_DIR/.processed"

# 监听文件变化
fswatch --recursive \
    --exclude="$EXCLUDE_PATTERNS" \
    --batch-marker \
    --latency 2 \
    "$DYLIBS_DIR" | while read line; do
    
    if [ "$line" = "BreakMarker" ]; then
        # 查找新的dylib文件
        for dylib in "$DYLIBS_DIR"/*.dylib; do
            if [ -f "$dylib" ]; then
                process_dylib "$dylib"
            fi
        done
    fi
done
