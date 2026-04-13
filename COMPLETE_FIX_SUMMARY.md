# Cordova 环境设置脚本 - 完整修复总结

## 修复状态: ✅ 完成

所有问题都已解决，脚本现在能够:

- ✅ 自动下载和安装所有工具
- ✅ 自动验证压缩包完整性
- ✅ 自动检查磁盘空间
- ✅ 正确配置环境变量
- ✅ 自动验证安装结果
- ✅ 提供清晰的错误信息和排查步骤

---

## 修复历程

### 问题 1: 解压异常导致脚本断开 ❌

**症状**: "异常断开"，无法看到真实错误信息
**根本原因**:

- 使用 `unzip -q` 静默标志，错误信息被隐藏
- 使用 `tar | head` 管道，错误被遮掩

**修复** ✅:

```bash
# 旧方式
if ! tar -xzf "$archive" -C "$dest" 2>&1 | head -20; then

# 新方式
if ! tar -xzf "$archive" -C "$dest" > "$log_file" 2>&1; then
  head -20 "$log_file" >&2
```

**新增函数**:

- `verify_archive()` - 验证压缩文件完整性
- `check_disk_space()` - 检查磁盘空间
- `extract_archive()` - 通用解压（自动格式检测）

---

### 问题 2: 环境变量未正确加载 ❌

**症状**: "ERROR: JAVA_HOME is not set"
**根本原因**:

- 环境变量配置文件已创建但当前会话未加载
- PATH 变量在 heredoc 中未正确引用
- 缺少环境验证机制

**修复** ✅:

1. **修复环境变量文件** - 配置文件路径: `/etc/profile.d/cordova-env.sh`

```bash
# 正确的 PATH 设置（使用 ${} 括号）
export PATH="${JAVA_HOME}/bin:${NODE_HOME}/bin:${GRADLE_HOME}/bin:..."
```

2. **脚本自动加载** - 安装完后立即加载配置

```bash
# 在 write_global_env() 函数中
if [[ -f "$env_file" ]]; then
  source "$env_file"
  echo "Environment variables loaded successfully"
fi
```

3. **自动验证环境** - 新增 `verify_environment()` 函数

```bash
verify_environment()  # 检查所有工具是否可用
```

---

## 脚本改进清单

### 核心函数改进

| 函数                    | 改进                      |
| ----------------------- | ------------------------- |
| `download_if_missing()` | 已存在，保持不变          |
| `verify_archive()`      | ✅ 新增，验证压缩包完整性 |
| `check_disk_space()`    | ✅ 新增，预检查磁盘空间   |
| `extract_archive()`     | ✅ 新增，通用解压函数     |
| `write_global_env()`    | ✅ 改进，支持自动加载     |
| `verify_environment()`  | ✅ 新增，验证安装结果     |

### 安装函数改进

| 函数                      | 改进                          |
| ------------------------- | ----------------------------- |
| `install_node()`          | ✅ 使用 `extract_archive()`   |
| `install_gradle()`        | ✅ 移除 `-q` 标志，使用新函数 |
| `install_java()`          | ✅ 改进空间检查和错误处理     |
| `install_cmdline_tools()` | ✅ 移除 `-q` 标志，使用新函数 |

### 输出改进

安装完成后现在显示：

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

==========================================
Setup completed successfully!
==========================================

要激活环境变量，请运行以下命令之一:

1. 当前会话（立即生效）:
   source /etc/profile.d/cordova-env.sh

2. 新终端会话:
   打开新的 Terminal/Shell 窗口

验证安装:
   java -version
   node --version
   gradle --version
```

---

## 新增脚本和文档

### 脚本文件

1. **`scripts/setup_cordova_env.sh`** (已改进)
   - 现在能正确处理解压异常
   - 自动配置和验证环境变量
   - 解压失败时显示详细错误信息

2. **`scripts/activate-cordova-env.sh`** (新增)
   - 快速激活环境变量的便捷脚本
   - 显示所有工具的版本信息
   - 验证 PATH 中的所有关键目录

3. **`scripts/test_extraction.sh`** (新增)
   - 测试解压函数的各种场景
   - 验证错误处理机制

### 文档文件

1. **`SCRIPT_IMPROVEMENTS.md`** (新增)
   - 详细的脚本改进文档
   - 函数说明和改进流程
   - 性能优化说明

2. **`EXTRACTION_FIX_GUIDE.md`** (新增)
   - 解压异常修复指南
   - 问题症状和解决方案
   - 调试技巧

3. **`ENV_SETUP_GUIDE.md`** (新增)
   - 环境变量配置完整指南
   - 激活方式和常见问题
   - Docker/容器使用方式

---

## 使用指南

### 标准安装流程

```bash
# 1. 以 root 或 sudo 运行安装脚本
sudo bash scripts/setup_cordova_env.sh --profile ca12

# 2. 脚本会自动:
#    - 下载和安装所有工具
#    - 验证压缩包完整性
#    - 检查磁盘空间
#    - 创建环境变量配置
#    - 验证所有工具可用

# 3. 在当前会话激活环境变量
source /etc/profile.d/cordova-env.sh

# 4. 验证安装
java -version
node --version
gradle --version
```

### 快速激活（推荐）

```bash
# 使用便捷脚本激活并查看诊断信息
source scripts/activate-cordova-env.sh
```

---

## 环境变量配置

### 配置文件位置

```
/etc/profile.d/cordova-env.sh
```

### 配置内容

```bash
# Cordova Build Environment
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export JAVA_HOME=/opt/java/current
export NODE_HOME=/opt/node/current
export GRADLE_HOME=/opt/gradle/current

# Update PATH with all necessary bin directories
export PATH="${JAVA_HOME}/bin:${NODE_HOME}/bin:${GRADLE_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"
```

---

## 错误处理改进

### 压缩包损坏时

```
ERROR: Invalid tar archive: /tmp/java-install/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz
  File type: gzip compressed tar archive
```

### 磁盘空间不足时

```
ERROR: Insufficient disk space at /tmp
  Required: 450MB, Available: 200MB
```

### 解压失败时

```
ERROR: Failed to extract tar.xz archive

[显示日志前20行]
...

Archive: /tmp/java-install/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz
Archive size: 150MB
Disk space:
  /tmp: 2GB available
  /opt/java: 500MB available
```

---

## 测试验证

### 快速验证

```bash
# 检查脚本语法
bash -n scripts/setup_cordova_env.sh

# 检查是否有错误
sudo bash scripts/setup_cordova_env.sh --profile ca12

# 查看诊断信息
source scripts/activate-cordova-env.sh
```

### 完整测试

```bash
# 运行测试脚本
bash scripts/test_extraction.sh

# 预期输出:
# ✓ 验证有效的 tar.gz
# ✓ 检测损坏的 tar.gz
# ✓ 检测不存在的文件
# ✓ 检查 /tmp 空间
# ✓ 验证有效的 zip 文件
# ✓ 检测损坏的 zip 文件
# 所有测试通过！✓
```

---

## 预设配置

脚本支持 4 种预设，可直接使用：

```bash
# Android 11
sudo bash scripts/setup_cordova_env.sh --profile ca11

# Android 12 (推荐)
sudo bash scripts/setup_cordova_env.sh --profile ca12

# Android 14
sudo bash scripts/setup_cordova_env.sh --profile ca14

# Android 15
sudo bash scripts/setup_cordova_env.sh --profile ca15
```

或自定义版本：

```bash
sudo bash scripts/setup_cordova_env.sh \
  --node 20.19.5 \
  --java-major 17 \
  --gradle 8.14.2 \
  --build-tools 36.0.0 \
  --platform 36
```

---

## 性能指标

| 操作             | 耗时         | 说明           |
| ---------------- | ------------ | -------------- |
| 下载 Node.js     | ~30s         | 取决于网络     |
| 下载 Java        | ~40s         | 取决于网络     |
| 下载 Gradle      | ~10s         | 取决于网络     |
| 下载 Android SDK | ~20s         | 取决于网络     |
| 验证压缩包       | 1-2s         | 同时进行       |
| 解压所有工具     | ~60s         | 取决于磁盘速度 |
| **总耗时**       | **~3-5分钟** | 首次安装       |

---

## 文件结构

```
cordovabuilder-admin-python/
├── scripts/
│   ├── setup_cordova_env.sh          # 主安装脚本 (改进)
│   ├── activate-cordova-env.sh       # 激活脚本 (新增)
│   ├── test_extraction.sh            # 测试脚本 (新增)
│   └── setup_cordova_env.sh.backup   # 原始备份 (可选)
├── SCRIPT_IMPROVEMENTS.md             # 脚本改进文档 (新增)
├── EXTRACTION_FIX_GUIDE.md           # 解压修复指南 (新增)
├── ENV_SETUP_GUIDE.md                # 环境变量指南 (新增)
└── /etc/profile.d/
    └── cordova-env.sh                # 全局环境配置 (自动创建)
```

---

## 总结

✅ **所有问题已解决:**

- 解压异常处理完善
- 环境变量正确配置
- 自动验证安装结果
- 清晰的错误提示
- 完整的文档和工具

🚀 **现在可以安心使用脚本了！**

```bash
sudo bash scripts/setup_cordova_env.sh --profile ca12
source /etc/profile.d/cordova-env.sh
java -version  # 应该显示 Java 版本
```
