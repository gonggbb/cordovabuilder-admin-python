# Cordova 脚本解压异常修复 - 快速参考

## 问题症状

- ❌ 脚本运行时"异常断开"
- ❌ 无法看到真实的解压错误信息
- ❌ `unzip -q` 导致失败时沉默
- ❌ 管道操作 `tar | head` 掩盖了实际错误

## 修复内容

### 1️⃣ 管道问题修复

**问题**: `tar -xzf file | head` 导致 tar 错误被忽视

**修复**:

```bash
# 旧方式 ❌
if ! tar -xzf "$archive" -C "$dest" 2>&1 | head -20; then

# 新方式 ✅
if ! tar -xzf "$archive" -C "$dest" > "$log_file" 2>&1; then
  head -20 "$log_file" >&2
```

### 2️⃣ 新增验证函数

```bash
# 验证压缩文件完整性
verify_archive "file.tar.gz"

# 检查磁盘空间
check_disk_space "/tmp" 1000  # 检查 1000MB

# 通用解压（支持所有格式）
extract_archive "file.tar.xz" "/target" "auto"
```

### 3️⃣ 改进的错误报告

解压失败时现在显示：

```
ERROR: Failed to extract tar.xz archive
Archive: /tmp/java-install/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz
Archive size: 150MB
Archive type: gzip compressed tar archive
Disk space:
  /tmp: 2GB available
  /opt/java: 500MB available

[错误日志前20行]
...
```

## 主要改进

| 方面     | 前          | 后                         |
| -------- | ----------- | -------------------------- |
| 错误显示 | 静默失败    | 明确的错误信息             |
| 文件验证 | ❌ 无       | ✅ 完整性检查              |
| 空间检查 | ❌ 无       | ✅ 预检查                  |
| 格式支持 | tar.xz 固定 | tar.\*.gz, .xz, .bz2, .zip |
| 日志记录 | ❌ 无       | ✅ 临时日志文件            |

## 使用方式（无变化）

```bash
# 基础用法
./setup_cordova_env.sh --profile ca12

# 自定义版本
./setup_cordova_env.sh --node 20.19.5 --java-major 17 --gradle 8.14.2

# 所有预设
./setup_cordova_env.sh --profile ca11  # Cordova 12 + Android 11
./setup_cordova_env.sh --profile ca12  # Cordova 12 + Android 12
./setup_cordova_env.sh --profile ca14  # Cordova 13 + Android 14
./setup_cordova_env.sh --profile ca15  # Cordova 13 + Android 15
```

## 调试技巧

### 如果仍然出现解压错误

1. **检查压缩包**

```bash
# 查看压缩包文件列表
tar -tzf /tmp/java-install/OpenJDK*.tar.gz | head -5

# 验证压缩包完整性
tar -tzf /tmp/java-install/OpenJDK*.tar.gz > /dev/null && echo "OK"
```

2. **检查磁盘空间**

```bash
df -h /tmp /opt/java
du -sh /tmp/java-install/*
```

3. **查看错误日志**

```bash
# 脚本生成的日志在解压失败时显示
# 查找临时日志
ls -la /tmp/extract_*.log

# 手动检查
head -20 /tmp/extract_*.log
```

4. **重试下载**

```bash
# 删除缓存的坏文件
rm /tmp/java-install/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz

# 重新运行脚本（会重新下载）
./setup_cordova_env.sh --profile ca12
```

## 受影响的工具

| 工具                      | 改进                             |
| ------------------------- | -------------------------------- |
| **Node.js**               | ✅ 改进错误检查                  |
| **Java**                  | ✅ 改进错误检查 + 磁盘空间预检查 |
| **Gradle**                | ✅ 移除 `-q` 标志，显示错误      |
| **Android cmdline-tools** | ✅ 移除 `-q` 标志，显示错误      |

## 测试方法

```bash
# 运行测试脚本
bash scripts/test_extraction.sh

# 预期输出
# ✓ 验证有效的 tar.gz
# ✓ 检测损坏的 tar.gz
# ✓ 检测不存在的文件
# ✓ 检查 /tmp 空间
# ✓ 验证有效的 zip 文件
# ✓ 检测损坏的 zip 文件
#
# 所有测试通过！✓
```

## 相关文件

- `scripts/setup_cordova_env.sh` - 主脚本（已改进）
- `scripts/test_extraction.sh` - 测试脚本（新增）
- `SCRIPT_IMPROVEMENTS.md` - 详细改进文档（新增）

## 反馈

如果仍然遇到问题，请：

1. 运行 `bash setup_cordova_env.sh --profile ca12` 并保存完整输出
2. 检查 `/tmp/extract_*.log` 的内容
3. 运行 `bash test_extraction.sh` 验证基础功能
4. 检查系统命令：`tar --version`, `unzip -h`, `curl --version`
