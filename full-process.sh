#!/bin/bash

# 完整的dylib→deb→GitHub自动流程

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DYLIB_FILE="$1"
COMMIT_MSG="${2:-自动打包新deb包}"

if [ -z "$DYLIB_FILE" ] || [ ! -f "$DYLIB_FILE" ]; then
    echo "❌ 用法: $0 /path/to/dylib.dylib [提交信息]"
    exit 1
fi

echo "🚀 开始自动打包流程..."

# 第一步：检查或创建配置
DYLIB_NAME=$(basename "$DYLIB_FILE" .dylib)
CONFIG_FILE="$REPO_DIR/deb-tools/${DYLIB_NAME}.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️  未找到配置文件，请先运行配置工具:"
    echo "   python3 $REPO_DIR/config-builder.py"
    exit 1
fi

# 第二步：打包成deb
echo "📦 步骤1: 打包dylib为deb..."
"$REPO_DIR/auto-build-deb.sh" "$DYLIB_FILE"

# 第三步：更新源索引（如果自动打包脚本没有做）
echo "🔄 步骤2: 更新源索引..."
"$REPO_DIR/update-packages.sh"

# 第四步：提交到Git
echo "📝 步骤3: 提交到本地Git..."
cd "$REPO_DIR"
git add debs/ Packages* Release 2>/dev/null || true

if ! git diff-index --quiet HEAD --; then
    git commit -m "🎁 $COMMIT_MSG

dylib: $DYLIB_NAME
时间: $(date '+%Y-%m-%d %H:%M:%S')"
else
    echo "   无新更改"
fi

# 第五步：推送到GitHub
echo "📤 步骤4: 推送到GitHub..."
git push origin main

echo ""
echo "✅ 完成！"
echo "📱 iOS上可以通过 Sileo 订阅源地址来使用:"
echo "   https://github.com/zxs-ai/repo"
