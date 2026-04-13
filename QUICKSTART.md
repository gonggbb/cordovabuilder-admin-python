# 🚀 Cordova 脚本 - 快速启动指南

## 5 分钟快速开始

### 第 1 步: 运行安装脚本

```bash
sudo bash scripts/setup_cordova_env.sh --profile ca12
```

脚本会自动：

- ✅ 下载和安装所有工具
- ✅ 创建软链接
- ✅ 配置环境变量
- ✅ 验证安装

### 第 2 步: 激活环境（二选一）

**方式 1 - 立即激活**（推荐）

```bash
source /etc/profile.d/cordova-env.sh
```

**方式 2 - 使用便捷脚本**

```bash
source scripts/activate-cordova-env.sh
```

### 第 3 步: 验证成功

```bash
java -version    # ✓ Java 17
node --version   # ✓ v20.19.5
gradle --version # ✓ Gradle 8.14.2
```

---

## 常见预设配置

```bash
# Android 11（旧版）
sudo bash scripts/setup_cordova_env.sh --profile ca11

# Android 12（推荐）
sudo bash scripts/setup_cordova_env.sh --profile ca12

# Android 14（新版）
sudo bash scripts/setup_cordova_env.sh --profile ca14

# Android 15（最新）
sudo bash scripts/setup_cordova_env.sh --profile ca15
```

---

## 自定义版本

```bash
sudo bash scripts/setup_cordova_env.sh \
  --node 20.19.5 \
  --java-major 17 \
  --gradle 8.14.2 \
  --build-tools 36.0.0 \
  --platform 36
```

---

## ⚠️ 常见问题

### 问题: 仍然看到 "JAVA_HOME is not set"

**解决**:

```bash
# 确保已运行激活命令
source /etc/profile.d/cordova-env.sh

# 验证环境变量
echo $JAVA_HOME  # 应该显示 /opt/java/current
```

### 问题: IDE 中仍然找不到 Java

**解决**: 在 IDE 设置中指定 `JAVA_HOME=/opt/java/current`

### 问题: 新终端中找不到命令

**解决**: 这是正常的，新终端会自动加载 `/etc/profile.d/cordova-env.sh`。如果仍然不行，添加到 `~/.bashrc`:

```bash
source /etc/profile.d/cordova-env.sh
```

---

## 文件结构

```
scripts/
├── setup_cordova_env.sh          # 主安装脚本 ✨ 已优化
├── activate-cordova-env.sh       # 快速激活脚本
└── test_extraction.sh            # 测试脚本

文档/
├── ENV_FIX_FINAL.md             # 完整修复说明 📖
├── ENV_SETUP_GUIDE.md           # 环境变量配置指南 📖
├── COMPLETE_FIX_SUMMARY.md      # 修复总结 📖
└── EXTRACTION_FIX_GUIDE.md      # 解压异常修复 📖
```

---

## 环境变量速查表

| 变量           | 值                    | 用途             |
| -------------- | --------------------- | ---------------- |
| `JAVA_HOME`    | `/opt/java/current`   | Java 开发工具包  |
| `NODE_HOME`    | `/opt/node/current`   | Node.js 运行环境 |
| `GRADLE_HOME`  | `/opt/gradle/current` | Gradle 构建工具  |
| `ANDROID_HOME` | `/opt/android-sdk`    | Android SDK      |

---

## 支持的平台

| 平台          | 支持 | 备注           |
| ------------- | ---- | -------------- |
| Ubuntu 20.04+ | ✅   | 推荐           |
| Debian 11+    | ✅   | 推荐           |
| CentOS 7+     | ✅   | 测试过         |
| Alpine Linux  | ✅   | 需要 glibc     |
| macOS         | ❌   | 脚本针对 Linux |
| Windows WSL   | ✅   | 推荐使用 WSL2  |

---

## 一行命令安装 + 激活

```bash
sudo bash scripts/setup_cordova_env.sh --profile ca12 && source /etc/profile.d/cordova-env.sh && java -version
```

---

## 更多帮助

- 📖 详细修复说明 → [`ENV_FIX_FINAL.md`](ENV_FIX_FINAL.md)
- 📖 环境配置指南 → [`ENV_SETUP_GUIDE.md`](ENV_SETUP_GUIDE.md)
- 📖 解压异常修复 → [`EXTRACTION_FIX_GUIDE.md`](EXTRACTION_FIX_GUIDE.md)
- 📖 完整改进总结 → [`COMPLETE_FIX_SUMMARY.md`](COMPLETE_FIX_SUMMARY.md)
- 📖 脚本改进详情 → [`SCRIPT_IMPROVEMENTS.md`](SCRIPT_IMPROVEMENTS.md)

---

**现在就开始吧！** 🎉
