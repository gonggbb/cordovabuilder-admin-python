# setup_cordova_env.sh 脚本改进总结

## 修复的解压异常问题

### 问题 1: 静默解压导致错误信息丢失

**症状**: `unzip -q` 导致解压失败时无法看到真实错误信息
**解决**: 移除 `-q` 标志，改用日志文件记录输出

### 问题 2: 管道错误处理不当

**症状**: `tar | head` 或 `unzip | head` 导致管道错误被忽视
**解决**: 将输出重定向到日志文件，而不使用管道

```bash
# 改前
if ! tar -xzf "$archive" -C "$dest" 2>&1 | head -20; then

# 改后
if ! tar -xzf "$archive" -C "$dest" > "$log_file" 2>&1; then
  head -20 "$log_file" >&2
```

### 问题 3: 缺少文件验证

**症状**: 不完整或损坏的压缩包会直接解压，导致后续失败
**解决**: 新增 `verify_archive()` 函数验证文件完整性

- 检测压缩格式（自动或手动指定）
- 验证 tar 包：`tar -tf`
- 验证 zip 包：`unzip -t`

### 问题 4: 缺少磁盘空间检查

**症状**: 磁盘空间不足导致解压中途失败，错误信息不明确
**解决**: 新增 `check_disk_space()` 函数

- 检查目标目录所在卷的空间
- 预留 3 倍压缩包大小的空间
- 提供清晰的错误信息

## 新增辅助函数

### 1. `check_disk_space(path, required_mb)`

检查指定路径所在卷是否有足够磁盘空间

**参数**:

- `path`: 目标路径
- `required_mb`: 需要的空间（默认 500MB）

**返回值**: 0 成功, 1 空间不足

### 2. `verify_archive(archive, archive_type)`

验证压缩文件的完整性和格式

**参数**:

- `archive`: 压缩文件路径
- `archive_type`: 类型 (auto/tar/zip，默认 auto)

**返回值**: 0 有效, 1 无效

### 3. `extract_archive(archive, dest, archive_type)`

通用解压函数，支持多种格式

**支持的格式**:

- `.tar.gz`, `.tgz` (tar.gz)
- `.tar.xz`, `.txz` (tar.xz)
- `.tar.bz2` (tar.bz2)
- `.tar` (plain tar)
- `.zip` (zip)

**参数**:

- `archive`: 压缩文件路径
- `dest`: 解压目标目录
- `archive_type`: 类型（默认自动检测）

**返回值**: 0 成功, 1 失败

## 改进的安装流程

### Node.js 安装

```
下载 → 验证格式 → 检查空间 → 清理旧目录 → 解压 → 验证目录 → 移动 → 创建软链接
```

### Gradle 安装

```
下载 → 验证格式 → 检查空间 → 清理旧目录 → 解压 → 验证目录 → 移动
```

### Java 安装

```
下载 → 预检查空间 → 获取目录名 → 清理旧目录 → 验证格式 → 检查空间 → 解压 →
验证目录 → 移动 → 设置权限
```

### Android cmdline-tools 安装

```
下载 → 验证格式 → 检查空间 → 清理目录 → 解压 → 移动 → 设置权限
```

## 错误诊断改进

### 解压错误时提供的信息

```
[错误消息] ❌
- Archive: /path/to/archive.tar.gz
- Archive size: 150MB
- Archive type: gzip compressed tar archive
- Disk space:
  /tmp: 2GB available
  /opt/java: 500MB available

[日志片段] (显示前 20 行)
...
```

### 常见问题排查步骤

1. **验证压缩包完整性**

   ```bash
   tar -tzf 'file.tar.gz' | head
   unzip -t 'file.zip'
   ```

2. **检查磁盘空间**

   ```bash
   df -h /tmp /opt/java
   ```

3. **检查文件权限**

   ```bash
   ls -lh 'archive.tar.gz'
   ```

4. **查看压缩包内容**
   ```bash
   tar -tzf 'file.tar.gz' | head -5
   ```

## 性能优化

### 日志文件管理

- 使用临时日志文件：`/tmp/extract_$$.log`
- 自动清理（解压成功后删除）
- 失败时保留用于调试（显示前 20 行）

### 空间检查优化

- 在解压前一次性检查
- 只检查必要的文件系统
- 提前报告空间不足避免部分解压

## 兼容性

### 支持的系统

- Ubuntu/Debian
- CentOS/RHEL
- Alpine Linux
- 其他 glibc 基础的 Linux 发行版

### 依赖命令

- `tar` (必需)
- `unzip` (必需)
- `bash` >= 4.0
- `curl` 或 `wget` (用于下载)

## 测试建议

1. **测试解压不同格式**

   ```bash
   ./setup_cordova_env.sh --profile ca12
   ```

2. **测试磁盘空间检查**

   ```bash
   # 在空间不足的卷上测试
   ./setup_cordova_env.sh --profile ca15
   ```

3. **测试损坏的压缩包**

   ```bash
   # 修改缓存目录中的压缩包，添加垃圾数据
   dd if=/dev/urandom of=/tmp/node-install/node-v20.19.5-linux-x64.tar.xz bs=1M count=1
   ./setup_cordova_env.sh --profile ca12
   ```

4. **测试权限问题**
   ```bash
   chmod 000 /opt/java
   ./setup_cordova_env.sh --profile ca12
   chmod 755 /opt/java
   ```
