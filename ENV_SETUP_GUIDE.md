# Cordova 环境变量配置修复指南

## 问题描述

安装完成后出现错误：

```
ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
```

**原因**: 环境变量配置文件已创建，但当前 Shell 会话还未加载这些变量。

## 解决方案

### 方案 1: 立即激活环境（推荐）

**方式 A - 运行激活脚本**

```bash
source scripts/activate-cordova-env.sh
```

**方式 B - 手动加载配置**

```bash
source /etc/profile.d/cordova-env.sh
```

### 方案 2: 新 Shell 会话自动加载

**下次打开终端时，环境变量会自动加载**（因为 shell 会自动执行 `/etc/profile.d/` 中的脚本）

```bash
# 新开一个终端，然后直接使用
java -version
gradle --version
```

## 完整安装与激活流程

```bash
# 1. 运行安装脚本
sudo bash scripts/setup_cordova_env.sh --profile ca12

# 2. 看到成功提示后，激活环境
source /etc/profile.d/cordova-env.sh

# 或者使用更好的激活脚本
source scripts/activate-cordova-env.sh

# 3. 验证安装
java -version
node --version
gradle --version
```

## 环境变量说明

安装脚本会创建 `/etc/profile.d/cordova-env.sh`，包含以下变量：

| 变量               | 值                       | 用途               |
| ------------------ | ------------------------ | ------------------ |
| `JAVA_HOME`        | `/opt/java/current`      | Java 开发工具包    |
| `NODE_HOME`        | `/opt/node/current`      | Node.js 运行环境   |
| `GRADLE_HOME`      | `/opt/gradle/current`    | Gradle 构建工具    |
| `ANDROID_HOME`     | `/opt/android-sdk`       | Android SDK        |
| `ANDROID_SDK_ROOT` | `/opt/android-sdk`       | Android SDK 根目录 |
| `PATH`             | 包含以上所有 `/bin` 目录 | 命令查找路径       |

## 验证脚本功能

### 自动验证（安装完成时自动运行）

安装脚本现在会自动验证所有工具是否可用，显示如下输出：

```
==========================================
验证环境设置
==========================================
✓ Java: /opt/java/current/bin/java
openjdk version "17.0.10" 2024-01-16

✓ Node.js: /opt/node/current/bin/node
v20.19.5

✓ Gradle: /opt/gradle/current/bin/gradle
Gradle 8.14.2

✓ Android SDK: /opt/android-sdk

环境变量:
  JAVA_HOME=/opt/java/current
  NODE_HOME=/opt/node/current
  GRADLE_HOME=/opt/gradle/current
  ANDROID_HOME=/opt/android-sdk

==========================================
✓ 所有环境检查通过
==========================================
```

### 手动激活脚本

使用 `activate-cordova-env.sh` 脚本随时验证环境：

```bash
source scripts/activate-cordova-env.sh

# 输出示例：
# ================================
# Cordova Build Environment
# ================================
#
# ✓ Java JDK
#    Path: /opt/java/current/bin/java
#    openjdk version "17.0.10" 2024-01-16
#
# ✓ Node.js
#    Path: /opt/node/current/bin/node
#    v20.19.5
#
# ...
```

## 常见问题

### Q1: 仍然看到 "JAVA_HOME is not set"

**A**: 确保已经运行了激活命令：

```bash
source /etc/profile.d/cordova-env.sh
echo $JAVA_HOME  # 应该显示 /opt/java/current
```

### Q2: Docker/容器中如何使用？

**A**: 在 Dockerfile 中添加：

```dockerfile
RUN bash scripts/setup_cordova_env.sh --profile ca12

# 在后续 RUN 命令中使用环境变量
ENV PATH="/opt/java/current/bin:/opt/node/current/bin:/opt/gradle/current/bin:${PATH}"
ENV JAVA_HOME=/opt/java/current
ENV ANDROID_HOME=/opt/android-sdk
```

### Q3: 在特定的 Shell 中持久化环境变量？

**A**: 添加到对应的 Shell 配置文件：

**Bash** (`~/.bashrc` 或 `~/.bash_profile`):

```bash
source /etc/profile.d/cordova-env.sh
```

**Zsh** (`~/.zshrc`):

```bash
source /etc/profile.d/cordova-env.sh
```

**Fish** (`~/.config/fish/config.fish`):

```fish
source /etc/profile.d/cordova-env.sh
```

### Q4: 如何修改安装位置？

**A**: 编辑 `setup_cordova_env.sh` 中的以下变量（第 20-25 行）：

```bash
ANDROID_SDK_ROOT="/opt/android-sdk"  # 改为你的目录
NODE_ROOT="/opt/node"                # 改为你的目录
JAVA_ROOT="/opt/java"                # 改为你的目录
GRADLE_ROOT="/opt/gradle"            # 改为你的目录
```

同时更新 `/etc/profile.d/cordova-env.sh`：

```bash
export JAVA_HOME=/your/custom/path/java/current
# ... 等等
```

### Q5: 权限问题（Permission denied）？

**A**: 确保以 root 或 sudo 运行：

```bash
sudo bash scripts/setup_cordova_env.sh --profile ca12
```

如果某个工具目录权限不对：

```bash
sudo chmod -R 755 /opt/java /opt/node /opt/gradle /opt/android-sdk
```

## 相关文件

| 文件                            | 用途                                   |
| ------------------------------- | -------------------------------------- |
| `setup_cordova_env.sh`          | 主安装脚本（已改进环境变量处理）       |
| `activate-cordova-env.sh`       | 激活和验证环境脚本（新增）             |
| `/etc/profile.d/cordova-env.sh` | 全局环境变量配置文件（由脚本自动创建） |
| `SCRIPT_IMPROVEMENTS.md`        | 脚本改进详情                           |
| `EXTRACTION_FIX_GUIDE.md`       | 解压异常修复指南                       |

## 快速参考

```bash
# 一键安装并激活
sudo bash scripts/setup_cordova_env.sh --profile ca12 && \
  source /etc/profile.d/cordova-env.sh

# 验证所有工具
source scripts/activate-cordova-env.sh

# 测试各工具
java -version && node --version && gradle --version
```

## 反馈

如果仍然有问题：

1. 运行 `source scripts/activate-cordova-env.sh` 查看诊断信息
2. 检查 `echo $PATH` 中是否包含所有工具目录
3. 检查 `/etc/profile.d/cordova-env.sh` 文件是否存在和可读
4. 查看脚本的验证输出（在完整安装足最后）
