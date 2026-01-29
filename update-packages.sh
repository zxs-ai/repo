#!/bin/bash

# 更新Sileo源的Packages索引文件

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEB_DIR="$REPO_DIR/debs"

echo "🔄 正在更新Packages索引..."

# 检查debs目录
if [ ! -d "$DEB_DIR" ]; then
    echo "❌ debs目录不存在"
    exit 1
fi

# 生成Packages文件
cd "$REPO_DIR"
dpkg-scanpackages -m "$DEB_DIR" > Packages

# 压缩Packages文件
bzip2 -fk Packages
gzip -fk Packages

echo "✅ Packages 文件已生成"
echo "✅ Packages.bz2 文件已生成"
echo "✅ Packages.gz 文件已生成"
