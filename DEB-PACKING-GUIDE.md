# 📦 Sileo DEB 自动打包系统

## ✨ 功能说明

这是一个完整的自动化系统，可以：
1. 将 dylib 文件自动打包成 deb 包
2. 自动更新 Sileo 源索引
3. 自动上传到 GitHub
4. 双向同步到 Mac 和 GitHub

## 🚀 快速开始

### 第一次使用：创建配置

```bash
# 1. 打开配置生成工具
python3 config-builder.py

# 2. 在窗口中：
#    - 选择 dylib 文件
#    - 填写包信息（包名、版本、描述等）
#    - 点击"保存配置"
```

### 自动打包流程

```bash
# 方式1：手动一次性打包
./full-process.sh /path/to/misaka.dylib "我的打包信息"

# 方式2：实时监听文件夹（推荐长期使用）
./auto-watch-and-build.sh
# 然后只需把 dylib 文件放入 dylibs-to-pack/ 目录即可自动打包
```

## 📁 文件夹结构

```
zxs-ai-repo/
├── debs/                          # deb 包存储
├── deb-tools/                     # dylib配置文件
├── dylibs-to-pack/                # 待打包的dylib文件夹（用于自动监听）
│   └── .processed/                # 已处理文件
├── config-builder.py              # 📝 配置生成工具（GUI）
├── auto-build-deb.sh              # 打包脚本
├── full-process.sh                # 完整自动流程（推荐使用）
├── auto-watch-and-build.sh        # 实时监听脚本
├── update-packages.sh             # 更新索引脚本
├── Packages                       # Sileo源索引
├── Release                        # 源配置文件
└── 其他（HTML、CSS等）             # 网页资源
```

## 💡 使用示例

### 示例1：快速打包 misaka.dylib

```bash
# 第一步：生成配置
python3 config-builder.py
# 选择 misaka.dylib，填写信息如：
# 包名: com.zxs.misaka
# 版本: 1.0
# 描述: Misaka 插件
# 主页: https://github.com/zxs-ai/repo

# 第二步：一键打包+上传
./full-process.sh /path/to/misaka.dylib
```

### 示例2：长期使用（监听模式）

```bash
# 第一步：启动监听（后台运行）
./auto-watch-and-build.sh &

# 第二步：以后只需拷贝 dylib 到指定目录
cp misaka.dylib dylibs-to-pack/
# 然后系统会自动：
#  ✅ 检测文件
#  ✅ 打包成deb
#  ✅ 更新索引
#  ✅ 上传GitHub
```

## 🔧 配置文件说明

配置文件保存在 `deb-tools/` 目录，格式如下：

```bash
# deb-tools/misaka.conf
PACKAGE_NAME='com.zxs.misaka'
PACKAGE_VERSION='1.0'
PACKAGE_MAINTAINER='zxs <applexyz@my.com>'
PACKAGE_HOMEPAGE='https://github.com/zxs-ai/repo'
PACKAGE_DESC='Misaka 美化插件'
```

## 📝 编辑现有配置

直接编辑 `deb-tools/` 中的 `.conf` 文件即可修改包信息。

## 🔍 查看日志

```bash
# 实时查看自动打包日志
tail -f .deb-build.log

# 查看源索引更新日志
tail -f .sync-watch.log
```

## 🌐 iOS 端使用

在 iOS 越狱手机上：

1. 打开 Sileo
2. 点击"源" → "编辑" → "添加源"
3. 输入源地址：`https://github.com/zxs-ai/repo`
4. 完成！现在可以在"浏览"中看到您的所有包

## 🐛 故障排除

### 问题：找不到dpkg-scanpackages
```bash
# 解决：安装dpkg（如果未安装）
brew install dpkg
```

### 问题：配置文件不存在
```bash
# 解决：先运行配置生成工具
python3 config-builder.py
```

### 问题：权限不足
```bash
# 解决：重新设置权限
chmod +x *.sh *.py
```

## 📚 详细命令参考

### auto-build-deb.sh
```bash
用法: ./auto-build-deb.sh /path/to/dylib
功能: 打包dylib为deb（需要先有配置文件）
```

### full-process.sh
```bash
用法: ./full-process.sh /path/to/dylib [提交信息]
功能: 完整流程（打包+索引+提交+推送）
推荐: ⭐⭐⭐ 最方便的选择
```

### auto-watch-and-build.sh
```bash
用法: ./auto-watch-and-build.sh
功能: 监听 dylibs-to-pack/ 目录，自动打包
推荐: ⭐⭐⭐⭐⭐ 最自动化的选择（长期使用）
```

## 🎯 工作流总结

```
您有 dylib 文件
    ↓
python3 config-builder.py  (填写包信息一次)
    ↓
./full-process.sh dylib    (自动完成所有步骤)
    ↓
GitHub 源自动更新
    ↓
iOS Sileo 可立即安装
```

## ❓ 常见问题

**Q: 为什么我的包在Sileo里看不到？**
A: 检查Release文件中的信息是否正确。运行 `cat Release` 查看。

**Q: 怎样修改已发布包的信息？**
A: 编辑 `deb-tools/` 中的配置文件，重新运行 `full-process.sh`。

**Q: 支持多个dylib同时打包吗？**
A: 支持！每个dylib创建一个配置文件，然后逐个运行 `full-process.sh` 或使用 `auto-watch-and-build.sh` 监听。

---

📖 更多帮助，请查看脚本内的注释。
