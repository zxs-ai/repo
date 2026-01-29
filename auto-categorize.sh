#!/bin/bash

# 自动给deb包添加分类标签（基于上传时间）
# 最近3天的包会被标记为 "Recent"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEB_DIR="$REPO_DIR/debs"

echo "🏷️  开始自动分类处理..."

# 获取当前时间戳（秒）
CURRENT_TIME=$(date +%s)
THREE_DAYS_SECONDS=$((3 * 24 * 60 * 60))  # 3天的秒数
CUTOFF_TIME=$((CURRENT_TIME - THREE_DAYS_SECONDS))

# 遍历每个deb文件
for deb in "$DEB_DIR"/*.deb; do
    if [ ! -f "$deb" ]; then
        continue
    fi
    
    # 获取deb的修改时间戳
    DEB_MTIME=$(stat -f%m "$deb")
    DEB_NAME=$(basename "$deb")
    
    # 判断是否在3天内
    if [ "$DEB_MTIME" -gt "$CUTOFF_TIME" ]; then
        echo "📌 $DEB_NAME → Recent（最近上传）"
    else
        echo "📁 $DEB_NAME → All"
    fi
done

echo "✅ 分类处理完成！"
