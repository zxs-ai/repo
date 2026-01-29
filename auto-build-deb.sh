#!/bin/bash

# 自动从dylib文件打包成deb的脚本
# 使用方式: ./auto-build-deb.sh misaka.dylib

set -e

DYLIB_FILE="$1"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEBS_DIR="$REPO_DIR/debs"
TOOLS_DIR="$REPO_DIR/deb-tools"

# 检查dylib文件是否存在
if [ -z "$DYLIB_FILE" ] || [ ! -f "$DYLIB_FILE" ]; then
    echo "❌ 错误：请提供有效的dylib文件路径"
    echo "用法: $0 /path/to/file.dylib"
    exit 1
fi

# 获取dylib文件名（不含扩展名）
DYLIB_NAME=$(basename "$DYLIB_FILE" .dylib)

echo "🚀 开始打包 dylib: $DYLIB_NAME"

# 检查配置文件
CONFIG_FILE="$TOOLS_DIR/${DYLIB_NAME}.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️  未找到配置文件: $CONFIG_FILE"
    echo "请先运行: python3 config-builder.py"
    exit 1
fi

# 读取配置
source "$CONFIG_FILE"

# 创建临时工作目录
WORK_DIR="/tmp/deb-build-$$"
mkdir -p "$WORK_DIR"
CONTROL_DIR="$WORK_DIR/DEBIAN"
mkdir -p "$CONTROL_DIR"

echo "📦 打包信息:"
echo "   包名: $PACKAGE_NAME"
echo "   版本: $PACKAGE_VERSION"
echo "   描述: $PACKAGE_DESC"

# 创建control文件
cat > "$CONTROL_DIR/control" << EOF
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Architecture: iphoneos-arm64
Maintainer: $PACKAGE_MAINTAINER
Homepage: $PACKAGE_HOMEPAGE
Depends:
Section: Tweaks
Description: $PACKAGE_DESC
EOF

# 创建postinst脚本（可选，用于安装后的操作）
mkdir -p "$WORK_DIR/Library/MobileSubstrate/DynamicLibraries"
cp "$DYLIB_FILE" "$WORK_DIR/Library/MobileSubstrate/DynamicLibraries/${DYLIB_NAME}.dylib"

# 创建plist文件（如果需要）
PLIST_FILE="$TOOLS_DIR/${DYLIB_NAME}.plist"
if [ -f "$PLIST_FILE" ]; then
    cp "$PLIST_FILE" "$WORK_DIR/Library/MobileSubstrate/DynamicLibraries/${DYLIB_NAME}.plist"
fi

# 打包成deb
DEB_FILENAME="${PACKAGE_NAME}_${PACKAGE_VERSION}_iphoneos-arm64.deb"
DEB_PATH="$DEBS_DIR/$DEB_FILENAME"

echo "📄 生成deb: $DEB_FILENAME"
dpkg-deb -b "$WORK_DIR" "$DEB_PATH"

if [ -f "$DEB_PATH" ]; then
    echo "✅ deb文件生成成功: $DEB_PATH"
    
    # 清理临时文件
    rm -rf "$WORK_DIR"
    
    # 重新生成Packages索引
    echo "🔄 更新源索引..."
    cd "$REPO_DIR"
    ./update-packages.sh
    
    echo "✨ 完成！现在可以推送到GitHub了"
    echo "   git add . && git commit -m '添加 $PACKAGE_NAME' && git push"
else
    echo "❌ deb文件生成失败"
    rm -rf "$WORK_DIR"
    exit 1
fi
