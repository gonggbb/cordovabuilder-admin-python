#!/usr/bin/env bash
# ============================================================================
# Cordova Build Environment Setup Script
# ============================================================================
# 用于安装和配置 Cordova 构建环境的 Bash 脚本
# 支持多种预设配置和自定义参数
# 
# 使用方法:
#   ./setup_cordova_env.sh --profile ca12
#   ./setup_cordova_env.sh --node 20.19.5 --java-major 17 --gradle 8.14.2
#
# 预设配置:
#   ca11: Cordova 12 + cordova-android 11.x (build-tools 32.0.0, gradle 7.4.2, Java 11, Node 18.20.8)
#   ca12: Cordova 12 + cordova-android 12.x (build-tools 33.0.2, gradle 7.6, Java 17, Node 18.20.8)
#   ca14: Cordova 13 + cordova-android 14.x (build-tools 35.0.0, gradle 8.13, Java 17, Node 20.19.5)
#   ca15: Cordova 13 + cordova-android 15.x (build-tools 36.0.0, gradle 8.14.2, Java 17, Node 20.19.5)
# ============================================================================
# 严格模式，确保脚本在遇到错误时立即退出，并且未定义的变量会导致错误
set -euo pipefail

# ============================================================================
# 默认配置
# ============================================================================
PROFILE="ca12"  # 默认预设: ca11 | ca12 | ca14 | ca15

# 版本变量 (可通过命令行参数覆盖)
NODE_VERSION=""
JAVA_MAJOR=""
JAVA_VERSION=""
GRADLE_VERSION=""
CMDLINE_TOOLS_VERSION=""
BUILD_TOOLS_VERSION=""
PLATFORM_API=""

# 安装目录
ANDROID_SDK_ROOT="/opt/android-sdk"
NODE_ROOT="/opt/node"
JAVA_ROOT="/opt/java"
GRADLE_ROOT="/opt/gradle"

# 缓存目录
NODE_CACHE="/tmp/node-install"
JAVA_CACHE="/tmp/java-install"
GRADLE_CACHE="/tmp/gradle-install"
CMDLINE_CACHE="/tmp/cmdline-tools-install"

# ============================================================================
# 帮助信息
# ============================================================================

# 显示使用帮助信息并退出
# 
# 功能说明:
#   向标准错误输出脚本的使用说明、参数选项和示例命令
#   然后以退出码 2 终止脚本执行
# 
# 参数:
#   无
# 
# 返回值:
#   不返回，直接调用 exit 2 终止脚本
# 
# 使用场景:
#   - 用户传入 -h 或 --help 参数时
#   - 用户传入未知参数时
#   - 预设配置无效时
# ============================================================================
usage() {
  cat >&2 <<'EOF'
Usage:
  setup_cordova_env.sh [--profile ca11|ca12|ca14|ca15]
    [--node VERSION] [--java-major 11|17] [--java VERSION]
    [--gradle VERSION] [--build-tools VERSION] [--platform API]
    [--cmdline VERSION]

Examples:
  setup_cordova_env.sh --profile ca14
  setup_cordova_env.sh --profile ca12 --java 17.0.10+7 --gradle 7.6
  setup_cordova_env.sh --node 20.19.5 --java-major 17 --build-tools 36.0.0 --platform 36 --gradle 8.14.2
EOF
  exit 2
}

# ============================================================================
# 预设配置应用
# ============================================================================

# 根据预设配置文件名应用对应的版本配置
# 
# 功能说明:
#   根据全局变量 PROFILE 的值，为各个组件设置默认版本号
#   如果用户已通过命令行参数指定了某个版本，则保留用户的设置（使用 :- 语法）
# 
# 支持的预设配置:
#   ca11: Node 18.20.8, Java 11 (latest), Gradle 7.4.2, build-tools 32.0.0, platform 32
#   ca12: Node 18.20.8, Java 17.0.10+7, Gradle 7.6, build-tools 33.0.2, platform 33
#   ca14: Node 20.19.5, Java 17.0.10+7, Gradle 8.13, build-tools 35.0.0, platform 35
#   ca15: Node 20.19.5, Java 17.0.10+7, Gradle 8.14.2, build-tools 36.0.0, platform 36
# 
# 参数:
#   无（依赖全局变量 PROFILE）
# 
# 返回值:
#   无显式返回值
# 
# 影响的全局变量:
#   - NODE_VERSION: Node.js 版本号
#   - JAVA_MAJOR: Java 主版本号
#   - JAVA_VERSION: Java 具体版本号
#   - GRADLE_VERSION: Gradle 版本号
#   - BUILD_TOOLS_VERSION: Android build-tools 版本号
#   - PLATFORM_API: Android Platform API 级别
# ============================================================================
apply_preset() {
  case "$PROFILE" in
    ca11)
      NODE_VERSION="${NODE_VERSION:-18.20.8}"
      JAVA_MAJOR="${JAVA_MAJOR:-17}"
      JAVA_VERSION="${JAVA_VERSION:-17.0.10+7}" 
      GRADLE_VERSION="${GRADLE_VERSION:-7.4.2}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-32.0.0}"
      PLATFORM_API="${PLATFORM_API:-32}"
      CMDLINE_TOOLS_VERSION="${CMDLINE_TOOLS_VERSION:-14742923}"
      ;;
    ca12)
      NODE_VERSION="${NODE_VERSION:-18.20.8}"
      JAVA_MAJOR="${JAVA_MAJOR:-17}"
      JAVA_VERSION="${JAVA_VERSION:-17.0.10+7}"
      GRADLE_VERSION="${GRADLE_VERSION:-7.6}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-33.0.2}"
      PLATFORM_API="${PLATFORM_API:-33}"
      CMDLINE_TOOLS_VERSION="${CMDLINE_TOOLS_VERSION:-14742923}"
      ;;
    ca13)
      NODE_VERSION="${NODE_VERSION:-20.19.5}"
      JAVA_MAJOR="${JAVA_MAJOR:-17}"
      JAVA_VERSION="${JAVA_VERSION:-17.0.10+7}"
      GRADLE_VERSION="${GRADLE_VERSION:-8.7}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-34.0.0}"
      PLATFORM_API="${PLATFORM_API:-34}"
      CMDLINE_TOOLS_VERSION="${CMDLINE_TOOLS_VERSION:-14742923}"
      ;;
    ca14)
      NODE_VERSION="${NODE_VERSION:-20.19.5}"
      JAVA_MAJOR="${JAVA_MAJOR:-17}"
      JAVA_VERSION="${JAVA_VERSION:-17.0.10+7}"
      GRADLE_VERSION="${GRADLE_VERSION:-8.13}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-35.0.0}"
      PLATFORM_API="${PLATFORM_API:-35}"
      CMDLINE_TOOLS_VERSION="${CMDLINE_TOOLS_VERSION:-14742923}"
      ;;

    ca15)
      NODE_VERSION="${NODE_VERSION:-20.19.5}"
      JAVA_MAJOR="${JAVA_MAJOR:-17}"
      JAVA_VERSION="${JAVA_VERSION:-17.0.10+7}"
      GRADLE_VERSION="${GRADLE_VERSION:-8.14.2}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-36.0.0}"
      PLATFORM_API="${PLATFORM_API:-36}"
      CMDLINE_TOOLS_VERSION="${CMDLINE_TOOLS_VERSION:-14742923}"

      ;;
  esac
}
# $# 代表参数个数
# $0: 脚本或函数本身的名称。
# $1, $2, $3...: 第 1、第 2、第 3 个参数。
# $#: 参数的总个数。
# $@: 所有的参数列表
# ${2:-}: 这是一种安全的取值方式。如果用户传了 --node 但后面没跟版本号，它会赋值为空字符串而不是报错。
# shift 2: 处理完一对参数（如 --node 和 18.20.8）后，将参数列表向前移动两位，继续处理下一个参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"; shift 2 ;;
    --node)
      NODE_VERSION="${2:-}"; shift 2 ;;
    --java-major)
      JAVA_MAJOR="${2:-}"; shift 2 ;;
    --java)
      JAVA_VERSION="${2:-}"; shift 2 ;;
    --gradle)
      GRADLE_VERSION="${2:-}"; shift 2 ;;
    --build-tools)
      BUILD_TOOLS_VERSION="${2:-}"; shift 2 ;;
    --platform)
      PLATFORM_API="${2:-}"; shift 2 ;;
    --cmdline)
      CMDLINE_TOOLS_VERSION="${2:-}"; shift 2 ;;
    -h|--help)
      usage ;;
    *)
      echo "Unknown argument: $1" >&2
      usage ;;
  esac
done

# 验证预设配置
if [[ "$PROFILE" != "ca11" && "$PROFILE" != "ca12" && "$PROFILE" != "ca14" && "$PROFILE" != "ca15" ]]; then
  echo "Invalid profile: $PROFILE" >&2
  usage
fi
# 检查当前用户是否为 root
if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# ============================================================================
# 工具函数
# ============================================================================

# 检查必需的系统命令是否存在
# 
# 功能说明:
#   验证指定的命令是否在当前系统的 PATH 中可用
#   如果命令不存在，输出错误信息并以退出码 3 终止脚本
# 
# 参数:
#   $1 - cmd: 要检查的命令名称（例如: "curl", "tar", "unzip"）
# 
# 返回值:
#   0 - 命令存在
#   不返回（命令不存在时调用 exit 3）
# 
# 使用示例:
#   require_cmd curl
#   require_cmd tar
# ============================================================================
require_cmd() {
  local cmd="$1"
  # 变量 $cmd 的值中包含空格或特殊字符，不加引号会导致 Shell 将其拆分为多个参数
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 3
  fi
}

# 下载文件到指定位置（如果文件尚不存在）
# 
# 功能说明:
#   从指定 URL 下载文件到本地路径
#   如果目标文件已存在，则跳过下载
#   支持 curl 和 wget 两种下载工具，优先使用 curl
#   包含重试机制、SSL 配置和文件完整性验证
# 
# 参数:
#   $1 - url: 文件的下载 URL
#   $2 - out: 本地保存的文件路径
# 
# 返回值:
#   0 - 下载成功或文件已存在
#   不返回（失败时调用 exit 3）
# 
# 特性:
#   - 自动创建父目录
#   - curl 配置：5次重试，每次间隔3秒，超时限制300秒
#   - wget 配置：5次尝试，重试间隔3秒，超时30秒
#   - 验证下载的文件不为空
#   - 显示文件大小信息
# 
# 依赖:
#   - curl 或 wget 命令必须可用
# ============================================================================
download_if_missing() {
  local url="$1"
  local out="$2"
  if [[ -f "$out" ]]; then
    echo "Already downloaded: $out"
    return 0
  fi
  echo "Downloading: $url"
  mkdir -p "$(dirname "$out")"
  if command -v curl >/dev/null 2>&1; then
    # 使用更强大的 curl 配置处理 SSL 和网络问题
    if ! curl -fL \
      --retry 5 \
      --retry-delay 3 \
      --retry-max-time 60 \
      --connect-timeout 30 \
      --max-time 300 \
      --tlsv1.2 \
      --ssl-reqd \
      -o "$out" "$url"; then
      echo "ERROR: Failed to download $url after multiple retries" >&2
      echo "Possible causes:" >&2
      echo "  1. Network connectivity issues" >&2
      echo "  2. SSL/TLS certificate problems" >&2
      echo "  3. Server temporarily unavailable" >&2
      echo "" >&2
      echo "Troubleshooting:" >&2
      echo "  - Check your network connection" >&2
      echo "  - Verify the URL is accessible: curl -I $url" >&2
      echo "  - Try manual download: curl -fL -o $out $url" >&2
      exit 3
    fi
  elif command -v wget >/dev/null 2>&1; then
    if ! wget --tries=5 --waitretry=3 --timeout=30 -O "$out" "$url"; then
      echo "ERROR: Failed to download $url after multiple retries" >&2
      exit 3
    fi
  else
    echo "Neither curl nor wget is available." >&2
    exit 3
  fi
  
  # 验证下载的文件不为空
  if [[ ! -s "$out" ]]; then
    echo "ERROR: Downloaded file is empty: $out" >&2
    rm -f "$out"
    exit 3
  fi
  
  echo "Download completed: $out ($(du -h "$out" | cut -f1))"
}

# 检测当前系统的 CPU 架构（用于 Node.js）
# 
# 功能说明:
#   通过 uname -m 获取系统架构信息
#   将其转换为 Node.js 下载 URL 中使用的架构标识符
# 
# 参数:
#   无
# 
# 返回值:
#   通过标准输出返回架构字符串:
#   - "x64": x86_64 架构
#   - "arm64": aarch64 或 arm64 架构
#   不支持的架构会输出错误信息并以退出码 4 终止
# 
# 输出示例:
#   x64
#   arm64
# ============================================================================
detect_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64) echo "x64" ;;
    aarch64|arm64) echo "arm64" ;;
    *)
      echo "Unsupported arch: $arch" >&2
      exit 4
      ;;
  esac
}

# 检测当前系统的 CPU 架构（用于 JDK）
# 
# 功能说明:
#   通过 uname -m 获取系统架构信息
#   将其转换为 Adoptium JDK 下载 URL 中使用的架构标识符
#   与 detect_arch 的区别在于 aarch64 返回 "aarch64" 而非 "arm64"
# 
# 参数:
#   无
# 
# 返回值:
#   通过标准输出返回架构字符串:
#   - "x64": x86_64 架构
#   - "aarch64": aarch64 或 arm64 架构
#   不支持的架构会输出错误信息并以退出码 4 终止
# 
# 输出示例:
#   x64
#   aarch64
# ============================================================================
detect_jdk_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64) echo "x64" ;;
    aarch64|arm64) echo "aarch64" ;;
    *)
      echo "Unsupported arch: $arch" >&2
      exit 4
      ;;
  esac
}

# 检查指定路径的可用磁盘空间
# 
# 功能说明:
#   检查给定路径所在文件系统的可用空间是否满足最低要求
#   如果路径不存在，会向上查找直到找到存在的父目录
# 
# 参数:
#   $1 - path: 要检查的路径
#   $2 - required_mb: 所需的最小空间（单位：MB），默认为 500MB
# 
# 返回值:
#   0 - 磁盘空间充足
#   1 - 磁盘空间不足（同时输出错误信息）
# 
# 使用示例:
#   check_disk_space /tmp 1024    # 检查 /tmp 是否有至少 1GB 空间
#   check_disk_space /opt/java     # 检查 /opt/java 是否有至少 500MB 空间
# ============================================================================
check_disk_space() {
  local path="$1"
  local required_mb="${2:-500}"  # 默认需要 500MB
  
  # 确保路径的父目录存在
  local check_path="$path"
  while [[ ! -e "$check_path" && "$check_path" != "/" ]]; do
    check_path="$(dirname "$check_path")"
  done
  
  local available
  available="$(df "$check_path" | awk 'NR==2 {print $4}')"
  
  if [[ $available -lt $((required_mb * 1024)) ]]; then
    echo "ERROR: Insufficient disk space at $check_path" >&2
    echo "  Required: ${required_mb}MB, Available: $((available / 1024))MB" >&2
    return 1
  fi
  return 0
}

# 验证压缩文件的完整性和有效性
# 
# 功能说明:
#   检查压缩文件是否存在且格式有效
#   支持自动检测压缩格式（tar.gz, tar.xz, tar.bz2, tar, zip）
#   使用相应的工具验证文件完整性
# 
# 参数:
#   $1 - archive: 压缩文件的路径
#   $2 - archive_type: 压缩类型（auto/tar/zip），默认为 auto 自动检测
# 
# 返回值:
#   0 - 文件有效或格式未知（发出警告）
#   1 - 文件不存在或验证失败（输出错误信息）
# 
# 验证方法:
#   - tar 格式: 使用 tar -tf 列出内容
#   - zip 格式: 使用 unzip -t 测试完整性
# 
# 使用示例:
#   verify_archive "node.tar.xz"           # 自动检测格式
#   verify_archive "gradle.zip" "zip"      # 明确指定为 zip 格式
# ============================================================================
verify_archive() {
  local archive="$1"
  local archive_type="${2:-auto}"  # auto, tar, zip
  
  if [[ ! -f "$archive" ]]; then
    echo "ERROR: Archive file not found: $archive" >&2
    return 1
  fi
  
  # 自动检测压缩格式
  if [[ "$archive_type" == "auto" ]]; then
    case "$archive" in
      *.tar.gz|*.tgz) archive_type="tar" ;;
      *.tar.xz|*.txz) archive_type="tar" ;;
      *.tar.bz2) archive_type="tar" ;;
      *.tar) archive_type="tar" ;;
      *.zip) archive_type="zip" ;;
      *) 
        echo "WARNING: Unknown archive type: $archive" >&2
        return 0
        ;;
    esac
  fi
  
  case "$archive_type" in
    tar)
      if ! tar -tf "$archive" >/dev/null 2>&1; then
        echo "ERROR: Invalid tar archive: $archive" >&2
        echo "  File type: $(file "$archive" 2>/dev/null || echo 'unknown')" >&2
        return 1
      fi
      ;;
    zip)
      if ! unzip -t "$archive" >/dev/null 2>&1; then
        echo "ERROR: Invalid zip archive: $archive" >&2
        echo "  File type: $(file "$archive" 2>/dev/null || echo 'unknown')" >&2
        return 1
      fi
      ;;
  esac
  
  return 0
}

# 通用的压缩文件解压函数
# 
# 功能说明:
#   将压缩文件解压到指定目录
#   支持多种压缩格式：tar.gz, tar.xz, tar.bz2, tar, zip
#   在解压前会验证文件完整性并检查磁盘空间
#   记录解压日志以便调试
# 
# 参数:
#   $1 - archive: 压缩文件的路径
#   $2 - dest: 解压目标目录
#   $3 - archive_type: 压缩类型（auto/tar/zip），默认为 auto 自动检测
# 
# 返回值:
#   0 - 解压成功
#   1 - 解压失败（输出详细错误信息）
# 
# 工作流程:
#   1. 验证压缩文件的有效性
#   2. 检查目标路径的磁盘空间（需要压缩包大小的 3 倍）
#   3. 创建目标目录
#   4. 根据文件扩展名选择相应的解压命令
#   5. 执行解压操作并记录日志
#   6. 清理临时日志文件
# 
# 依赖:
#   - verify_archive: 验证压缩文件
#   - check_disk_space: 检查磁盘空间
#   - tar/unzip: 系统解压工具
# 
# 使用示例:
#   extract_archive "node.tar.xz" /tmp
#   extract_archive "gradle.zip" /opt/gradle "zip"
# ============================================================================
extract_archive() {
  local archive="$1"
  local dest="$2"
  local archive_type="${3:-auto}"
  local log_file="/tmp/extract_$$.log"
  
  # 验证文件
  if ! verify_archive "$archive" "$archive_type"; then
    return 1
  fi
  
  # 检查磁盘空间（需要解压后的大小的两倍）
  local size_mb=$(($(du -m "$archive" | cut -f1) * 3))
  if ! check_disk_space "$dest" "$size_mb"; then
    return 1
  fi
  
  mkdir -p "$dest"
  
  case "$archive" in
    *.tar.gz|*.tgz)
      echo "Extracting tar.gz: $archive"
      if ! tar -xzf "$archive" -C "$dest" > "$log_file" 2>&1; then
        echo "ERROR: Failed to extract tar.gz archive" >&2
        head -20 "$log_file" >&2
        rm -f "$log_file"
        return 1
      fi
      rm -f "$log_file"
      ;;
    *.tar.xz|*.txz)
      echo "Extracting tar.xz: $archive"
      if ! tar -xJf "$archive" -C "$dest" > "$log_file" 2>&1; then
        echo "ERROR: Failed to extract tar.xz archive" >&2
        head -20 "$log_file" >&2
        rm -f "$log_file"
        return 1
      fi
      rm -f "$log_file"
      ;;
    *.tar.bz2)
      echo "Extracting tar.bz2: $archive"
      if ! tar -xjf "$archive" -C "$dest" > "$log_file" 2>&1; then
        echo "ERROR: Failed to extract tar.bz2 archive" >&2
        head -20 "$log_file" >&2
        rm -f "$log_file"
        return 1
      fi
      rm -f "$log_file"
      ;;
    *.tar)
      echo "Extracting tar: $archive"
      if ! tar -xf "$archive" -C "$dest" > "$log_file" 2>&1; then
        echo "ERROR: Failed to extract tar archive" >&2
        head -20 "$log_file" >&2
        rm -f "$log_file"
        return 1
      fi
      rm -f "$log_file"
      ;;
    *.zip)
      echo "Extracting zip: $archive"
      if ! unzip -q "$archive" -d "$dest" > "$log_file" 2>&1; then
        echo "ERROR: Failed to extract zip archive" >&2
        head -20 "$log_file" >&2
        rm -f "$log_file"
        return 1
      fi
      rm -f "$log_file"
      ;;
    *)
      echo "ERROR: Unknown archive format: $archive" >&2
      return 1
      ;;
  esac
  
  return 0
}

# 获取指定主版本的最新 Temurin JDK 下载 URL
# 
# 功能说明:
#   通过 Adoptium API 查询指定 Java 主版本的最新 JDK 下载地址
#   自动检测系统架构并获取对应平台的 JDK
# 
# 参数:
#   $1 - major: Java 主版本号（例如: 11, 17, 21）
# 
# 返回值:
#   通过标准输出返回完整的 JDK 下载 URL
#   如果 API 调用失败或找不到匹配的版本，可能返回空字符串
# 
# 输出示例:
#   https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz
# 
# 依赖:
#   - require_cmd: 检查 curl 命令
#   - detect_jdk_arch: 检测系统架构
# 
# API 端点:
#   https://api.adoptium.net/v3/assets/latest/{major}/hotspot
# 
# 使用示例:
#   url=$(get_latest_temurin_url 17)
# ============================================================================
get_latest_temurin_url() {
  local major="$1"
  local jdk_arch
  jdk_arch="$(detect_jdk_arch)"
  # Use Adoptium API to get latest Temurin JDK for the major version.
  # We only need the first "link" field from the JSON payload.
  require_cmd curl
  local api
  api="https://api.adoptium.net/v3/assets/latest/${major}/hotspot?os=linux&arch=${jdk_arch}&image_type=jdk"
  curl -fsSL "$api" | grep -m1 '"link"' | sed -E 's/.*"link"\s*:\s*"([^"]+)".*/\1/'
}

# 根据具体版本号构建 Temurin JDK 下载 URL
# 
# 功能说明:
#   根据完整的 Java 版本号构造 GitHub 上的 Temurin JDK 下载地址
#   处理版本号中的特殊字符（+ 替换为 %2B 用于 URL，替换为 _ 用于文件名）
# 
# 参数:
#   $1 - version: 完整的 Java 版本号（例如: "17.0.10+7"）
# 
# 返回值:
#   通过标准输出返回完整的 JDK 下载 URL
# 
# URL 格式:
#   https://github.com/adoptium/temurin{major}-binaries/releases/download/jdk-{version_url}/OpenJDK{major}U-jdk_{arch}_linux_hotspot_{version_num}.tar.gz
# 
# 依赖:
#   - detect_jdk_arch: 检测系统架构
# 
# 使用示例:
#   url=$(get_temurin_url_from_version "17.0.10+7")
#   # 返回: https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz
# ============================================================================
get_temurin_url_from_version() {
  local version="$1"
  local major="${version%%.*}"
  local version_num="${version//+/_}"
  local version_url="${version//+/%2B}"
  local jdk_arch
  jdk_arch="$(detect_jdk_arch)"
  echo "https://github.com/adoptium/temurin${major}-binaries/releases/download/jdk-${version_url}/OpenJDK${major}U-jdk_${jdk_arch}_linux_hotspot_${version_num}.tar.gz"
}

# ============================================================================
# 安装函数
# ============================================================================
# node-v20.19.5-linux-x64.tar.xz
# 安装 Node.js
# 下载并安装指定版本的 Node.js，配置软链接指向当前版本
# -d 是一个文件测试操作符，用于判断指定的路径是否是一个存在的目录 
# -f: 判断是否为存在的普通文件 (File)。
# -e: 判断路径是否存在 (Exist)，不管是文件还是目录。
# -x: 判断文件是否具有可执行权限 (Executable)。
# 参数:
#   $1 - version: Node.js 版本号（例如: "20.19.5"）
# 
# 返回值:
#   无显式返回值，通过 exit code 表示执行状态
#   0 - 成功安装或已存在
#   非0 - 安装失败（由 download_if_missing 或其他命令抛出）
# 
# 依赖:
#   - detect_arch: 检测系统架构
#   - download_if_missing: 下载文件（如果不存在）
#   - NODE_CACHE: Node.js 安装包缓存目录
#   - NODE_ROOT: Node.js 安装根目录
#   - SUDO: sudo 命令（可能需要权限）
# ============================================================================
install_node() {
  local version="$1"
  local arch
  arch="$(detect_arch)"
  local archive="${NODE_CACHE}/node-v${version}-linux-${arch}.tar.xz"
  local url="https://nodejs.org/dist/v${version}/node-v${version}-linux-${arch}.tar.xz"
  local install_dir="${NODE_ROOT}/node-v${version}"

  # 下载 Node.js 安装包到缓存目录
  download_if_missing "$url" "$archive"

  # 检查是否已安装，避免重复安装
  if [[ ! -d "$install_dir" ]]; then
    echo "Installing Node.js ${version} -> ${install_dir}"
    $SUDO mkdir -p "$NODE_ROOT"
    
    # 清理可能存在的旧目录
    if [[ -d "/tmp/node-v${version}-linux-${arch}" ]]; then
      $SUDO rm -rf "/tmp/node-v${version}-linux-${arch}"
    fi
    
    # 验证并解压
    if ! extract_archive "$archive" /tmp "auto"; then
      echo "ERROR: Failed to extract Node.js archive" >&2
      echo "Archive: $archive" >&2
      echo "Archive size: $(du -h "$archive" | cut -f1)" >&2
      exit 4
    fi
    
    # 验证解压结果
    if [[ ! -d "/tmp/node-v${version}-linux-${arch}" ]]; then
      echo "ERROR: Extracted Node.js directory does not exist" >&2
      exit 4
    fi
    
    # 移动至安装目录
    $SUDO rm -rf "$install_dir"
    if ! $SUDO mv "/tmp/node-v${version}-linux-${arch}" "$install_dir"; then
      echo "ERROR: Failed to move Node.js installation" >&2
      exit 4
    fi
    
    echo "Node.js installation completed successfully"
  else
    echo "Node.js already installed: $install_dir"
  fi

  # 创建或更新软链接，指向当前安装的版本
  # -f (Force):
  $SUDO ln -sfn "$install_dir" "${NODE_ROOT}/current"
}

# 安装 Gradle
# 下载并安装指定版本的 Gradle 构建工具
# gradle-8.14.2-bin.zip
# 
# 参数:
#   $1 - version: Gradle 版本号（例如: "8.14.2"）
# 返回值:
#   无显式返回值，失败时通过 exit code 退出
install_gradle() {
  local version="$1"
  local archive="${GRADLE_CACHE}/gradle-${version}-bin.zip"
  local url="https://services.gradle.org/distributions/gradle-${version}-bin.zip"
  local install_dir="${GRADLE_ROOT}/gradle-${version}"

  download_if_missing "$url" "$archive"

  if [[ ! -d "$install_dir" ]]; then
    echo "Installing Gradle ${version} -> ${install_dir}"
    $SUDO mkdir -p "$GRADLE_ROOT"
    
    # 清理可能存在的旧目录
    if [[ -d "/tmp/gradle-${version}" ]]; then
      $SUDO rm -rf "/tmp/gradle-${version}"
    fi
    
    # 验证并解压
    if ! extract_archive "$archive" /tmp "auto"; then
      echo "ERROR: Failed to extract Gradle archive" >&2
      echo "Archive: $archive" >&2
      echo "Archive size: $(du -h "$archive" | cut -f1)" >&2
      echo "Troubleshooting: Check disk space, archive integrity, or permissions" >&2
      exit 4
    fi
    
    # 验证解压结果
    if [[ ! -d "/tmp/gradle-${version}" ]]; then
      echo "ERROR: Extracted Gradle directory does not exist" >&2
      exit 4
    fi
    
    # 移动至安装目录
    $SUDO rm -rf "$install_dir"
    if ! $SUDO mv "/tmp/gradle-${version}" "$install_dir"; then
      echo "ERROR: Failed to move Gradle installation" >&2
      exit 4
    fi
    
    echo "Gradle installation completed successfully"
  else
    echo "Gradle already installed: $install_dir"
  fi
}

# 安装 Java JDK
# 从 Adoptium (Temurin) 下载并安装指定版本的 Java JDK
# 参数:
#   $1 - major: Java 主版本号（如 8, 11, 17, 21 等）
#   $2 - version: 具体的 Java 版本号，为空则安装该主版本的最新版本
# 返回值:
#   无显式返回值，失败时通过 exit 5 退出脚本
install_java() {
  local major="$1"
  local version="$2"  # empty means "latest for major"
  local url

  # 根据是否指定具体版本获取对应的下载 URL 
  # -n 是一个字符串测试操作符，用于判断字符串的长度是否不为零
  if [[ -n "$version" ]]; then
    url="$(get_temurin_url_from_version "$version")"
  else
    url="$(get_latest_temurin_url "$major")"
  fi

  local file_name
  file_name="$(basename "$url")"
  local archive="${JAVA_CACHE}/${file_name}"
  local install_dir

  # 确定 Java 安装目录路径 
  # %%: 表示从变量值的末尾开始匹配，并删除最长的匹配部分 ${version%%+*} 会找到第一个 +，并把 +7 删掉
  if [[ -n "$version" ]]; then
    install_dir="${JAVA_ROOT}/jdk-${version%%+*}"
  else
    install_dir="${JAVA_ROOT}/jdk-${major}"
  fi

  # 下载 Java 安装包（如果缓存中不存在）
  download_if_missing "$url" "$archive"

  # 检查是否已安装，未安装则执行安装流程
  if [[ ! -d "$install_dir" ]]; then
    echo "Installing Java ${major} -> ${install_dir}"
    
    # 1. 确保目标根目录存在
    $SUDO mkdir -p "$JAVA_ROOT"
    
    # 2. 确保 /tmp 有足够空间
    if ! check_disk_space /tmp $(($(du -m "$archive" | cut -f1) * 3)); then
      echo "ERROR: Insufficient space in /tmp for Java installation" >&2
      exit 5
    fi
    
    # 3. 获取压缩包内的顶层目录名
    local extracted
    echo "Checking archive: $archive"
    # -tzf 列出 tar.gz 包的内容，grep 提取顶层目录，sort -u 去重，head -n1 取第一个
    extracted="$(tar -tzf "$archive" 2>/dev/null | grep -o '^[^/]\+' | sort -u | head -n1)"
    # -z 是字符串测试操作符，用于判断字符串的长度是否为零（Zero
    if [[ -z "$extracted" ]]; then
      echo "ERROR: Cannot determine extracted directory name from archive" >&2
      echo "Archive: $archive" >&2
      echo "Check if archive is valid: tar -tzf '$archive' | head" >&2
      exit 5
    fi
    
    echo "Archive contains: $extracted"
    
    # 4. 清理 /tmp 下可能存在的同名旧目录，防止权限冲突
    if [[ -d "/tmp/${extracted}" ]]; then
      echo "Cleaning up existing directory: /tmp/${extracted}"
      $SUDO rm -rf "/tmp/${extracted}" || {
        echo "WARNING: Could not remove /tmp/${extracted}, attempting forced extraction" >&2
      }
    fi

    # 5. 验证并解压压缩包
    echo "Extracting Java archive..."
    if ! extract_archive "$archive" /tmp "auto"; then
      echo "ERROR: Failed to extract Java archive: $archive" >&2
      echo "Archive size: $(du -h "$archive" | cut -f1)" >&2
      echo "Archive type: $(file "$archive" 2>/dev/null || echo 'unknown')" >&2
      echo "Disk space:" >&2
      df -h /tmp "$JAVA_ROOT" >&2 || true
      exit 5
    fi
    
    # 6. 验证解压后的目录是否存在
    if [[ ! -d "/tmp/${extracted}" ]]; then
      echo "ERROR: Extracted directory does not exist: /tmp/${extracted}" >&2
      echo "Contents of /tmp (showing first 10 entries):" >&2
      ls -la /tmp/ 2>/dev/null | head -10 >&2 || true
      exit 5
    fi
    
    echo "Extraction successful. Directory: /tmp/${extracted}"
    
    # 7. 清理旧的安装目录
    $SUDO rm -rf "$install_dir"
    
    # 8. 移动解压后的目录到安装位置
    echo "Moving to installation directory: $install_dir"
    if ! $SUDO mv "/tmp/${extracted}" "$install_dir"; then
      echo "ERROR: Failed to move Java installation to $install_dir" >&2
      echo "Source exists: $([ -d "/tmp/${extracted}" ] && echo 'yes' || echo 'no')" >&2
      echo "Target parent exists: $([ -d "$(dirname "$install_dir")" ] && echo 'yes' || echo 'no')" >&2
      echo "Source permissions: $(ls -ld "/tmp/${extracted}" 2>/dev/null || echo 'N/A')" >&2
      echo "Disk space:" >&2
      df -h /tmp "$JAVA_ROOT" >&2 || true
      exit 5
    fi
    
    # 9. 设置正确的权限
    $SUDO chmod -R 755 "$install_dir"
    
    echo "Java installation completed successfully"
    echo "Installed to: $install_dir"
  else
    echo "Java already installed: $install_dir"
  fi
}

# 安装 Android Command Line Tools
# 下载并安装 Android SDK 命令行工具
# 采用基于版本号的目录管理，并自动更新 latest 软链接
# 
# 参数:
#   $1 - version: cmdline-tools 版本号（例如: "14742923"）
# 
# 返回值:
#   无显式返回值，失败时通过 exit code 退出
install_cmdline_tools() {
  local version="$1"
  echo "Installing Android cmdline-tools version: $version"
  local archive="${CMDLINE_CACHE}/commandlinetools-linux-${version}_latest.zip"
  local url="https://dl.google.com/android/repository/commandlinetools-linux-${version}_latest.zip"
  
  # 定义基于版本的安装目录和统一的 latest 软链接
  local install_dir="${ANDROID_SDK_ROOT}/cmdline-tools/${version}"
  local latest_link="${ANDROID_SDK_ROOT}/cmdline-tools/latest"
  local sdkmanager_path="${install_dir}/bin/sdkmanager"

  download_if_missing "$url" "$archive"

  if [[ ! -d "$install_dir" ]]; then
    echo "Installing Android cmdline-tools ${version} -> ${install_dir}"
    $SUDO mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"
    
    # 清理临时目录
    if [[ -d /tmp/cmdline-tools-extract ]]; then
      $SUDO rm -rf /tmp/cmdline-tools-extract
    fi
    
    # 解压到临时目录
    if ! extract_archive "$archive" /tmp/cmdline-tools-extract "auto"; then
      echo "ERROR: Failed to extract cmdline-tools archive" >&2
      echo "Archive: $archive" >&2
      echo "Archive size: $(du -h "$archive" | cut -f1)" >&2
      exit 5
    fi
    
    # 移动至目标位置 (处理压缩包内可能存在的顶层 cmdline-tools 文件夹)
    if [[ -d /tmp/cmdline-tools-extract/cmdline-tools ]]; then
      if ! $SUDO mv /tmp/cmdline-tools-extract/cmdline-tools "${install_dir}"; then
        echo "ERROR: Failed to move cmdline-tools" >&2
        exit 5
      fi
    else
      if ! $SUDO mv /tmp/cmdline-tools-extract "${install_dir}"; then
        echo "ERROR: Failed to move cmdline-tools" >&2
        exit 5
      fi
    fi
    
    # 设置执行权限
    $SUDO chmod -R 755 "${install_dir}/bin"
    
    # 清理临时目录
    $SUDO rm -rf /tmp/cmdline-tools-extract
    
    echo "Android cmdline-tools installation completed successfully"
  else
    echo "Android cmdline-tools already installed: ${install_dir}"
  fi

  # 统一更新 latest 软链接，确保指向当前配置的版本
  echo "Updating symlink: ${latest_link} -> ${install_dir}"
  
  # 关键步骤：无论 latest 是文件、目录还是链接，都强制删除，确保 ln -sfn 能成功创建纯软链接
  $SUDO rm -rf "${latest_link}"
  # 操作（删除并重建 latest 软链接）只会影响管理工具本身，不会影响你已经安装好的 Android 平台包和构建工具
  if ! $SUDO ln -sfn "${install_dir}" "${latest_link}"; then
    echo "ERROR: Failed to create symlink for cmdline-tools" >&2
    exit 5
  fi
  
  echo "Symlink updated successfully."
}

# 获取 sdkmanager 工具的完整路径
# 
# 功能说明:
#   返回 Android SDK cmdline-tools 中 sdkmanager 命令的绝对路径
#   sdkmanager 是 Android SDK 的包管理工具，用于安装和管理 SDK 组件
# 
# 参数:
#   无
# 
# 返回值:
#   通过标准输出返回 sdkmanager 的路径字符串
# 
# 输出示例:
#   /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager
# 
# 使用场景:
#   在安装 Android SDK 组件之前获取工具路径
#   验证 cmdline-tools 是否正确安装
# 
# 使用示例:
#   sdkmanager_path=$(sdkmanager_cmd)
#   "$sdkmanager_path" --list
# ============================================================================
sdkmanager_cmd() {
  echo "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
}

# 安装指定的 Android SDK 组件
# 
# 功能说明:
#   使用 sdkmanager 工具安装 Android SDK 的核心组件
#   包括 platform-tools、指定版本的 platform 和 build-tools
#   自动接受所有许可证协议
# 
# 参数:
#   $1 - build_tools: Android build-tools 版本号（例如: "33.0.2"）
#   $2 - platform_api: Android Platform API 级别（例如: 33）
# 
# 返回值:
#   无显式返回值，失败时以退出码 5 终止脚本
# 
# 安装的组件:
#   - platform-tools: Android 平台工具（adb, fastboot 等）
#   - platforms;android-{API}: 指定 API 级别的 Android 平台
#   - build-tools;{version}: 指定版本的构建工具
# 
# 依赖:
#   - sdkmanager_cmd: 获取 sdkmanager 路径
#   - ANDROID_SDK_ROOT: Android SDK 根目录环境变量
# 
# 注意事项:
#   - 会自动设置 ANDROID_HOME 和 ANDROID_SDK_ROOT 环境变量
#   - 使用 yes 命令自动接受许可证
#   - 如果 sdkmanager 不可用，会输出错误并退出
# 
# 使用示例:
#   install_android_packages "33.0.2" "33"
# ============================================================================
install_android_packages() {
  local build_tools="$1"
  local platform_api="$2"
  local sdkmanager
  sdkmanager="$(sdkmanager_cmd)"

  if [[ ! -x "$sdkmanager" ]]; then
    echo "sdkmanager not found. Did cmdline-tools install succeed?" >&2
    exit 5
  fi

  export ANDROID_HOME="${ANDROID_SDK_ROOT}"
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
  yes | "$sdkmanager" --licenses >/dev/null 2>&1 || true
  "$sdkmanager" "platform-tools" "platforms;android-${platform_api}" "build-tools;${build_tools}"
}

# 写入全局环境变量配置文件
# 
# 功能说明:
#   创建 /etc/profile.d/cordova-env.sh 文件，配置 Cordova 构建环境的全局环境变量
#   同时在当前 shell 会话中立即生效这些环境变量
#   该文件会在用户登录或打开新终端时自动加载
# 
# 参数:
#   无
# 
# 返回值:
#   无显式返回值
# 
# 配置的环境变量:
#   - ANDROID_HOME: Android SDK 根目录 (/opt/android-sdk)
#   - ANDROID_SDK_ROOT: Android SDK 根目录（同上）
#   - JAVA_HOME: Java 安装目录 (/opt/java/current)
#   - NODE_HOME: Node.js 安装目录 (/opt/node/current)
#   - GRADLE_HOME: Gradle 安装目录 (/opt/gradle/current)
#   - PATH: 追加所有工具的 bin 目录到 PATH
# 
# 文件权限:
#   设置为 644（所有者可读写，其他用户只读）
# 
# 副作用:
#   - 创建或覆盖 /etc/profile.d/cordova-env.sh
#   - 修改当前 shell 的环境变量
#   - 可能需要 sudo 权限
# 
# 注意事项:
#   - 使用 literal paths 而非变量引用，避免 profile.d 中的 shell 展开问题
#   - 在更新 PATH 时会检查避免重复添加
# 
# 使用示例:
#   write_global_env
#   # 之后运行: source /etc/profile.d/cordova-env.sh
# ============================================================================
write_global_env() {
  local env_file="/etc/profile.d/cordova-env.sh"
  echo "Writing global environment: ${env_file}"
  $SUDO tee "$env_file" >/dev/null <<'EOF'
# Cordova Build Environment
# Auto-generated by setup_cordova_env.sh
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export JAVA_HOME=/opt/java/current
export NODE_HOME=/opt/node/current
export GRADLE_HOME=/opt/gradle/current

# Update PATH with all necessary bin directories
# Note: Using literal paths instead of variables due to shell expansion in profile.d
export PATH="/opt/java/current/bin:/opt/node/current/bin:/opt/gradle/current/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:${PATH}"
EOF
  $SUDO chmod 644 "$env_file"
  echo "Configuration written to: $env_file"
  
  # 在当前 shell 中立即设置环境变量，并扩展 PATH
  export ANDROID_HOME=/opt/android-sdk
  export ANDROID_SDK_ROOT=/opt/android-sdk
  export JAVA_HOME=/opt/java/current
  export NODE_HOME=/opt/node/current
  export GRADLE_HOME=/opt/gradle/current
  
  # 确保 PATH 包含所有必要的目录（避免重复）
  local new_path="/opt/java/current/bin:/opt/node/current/bin:/opt/gradle/current/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools"
  if [[ ":$PATH:" != *":$new_path:"* ]]; then
    export PATH="$new_path:$PATH"
  fi
  
  echo "Environment variables configured in current session"
}

# 验证 Cordova 构建环境的完整性和正确性
# 
# 功能说明:
#   全面检查所有已安装的组件和环境变量配置
#   验证 Java、Node.js、Gradle 和 Android SDK 是否正确安装并可执行
#   输出详细的检查结果和诊断信息
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 所有检查通过
#   1 - 部分检查失败（输出失败数量）
# 
# 检查项目:
#   1. 环境变量设置（JAVA_HOME, NODE_HOME, GRADLE_HOME, ANDROID_HOME）
#   2. PATH 中包含必要的 bin 目录
#   3. Java 可执行文件和版本
#   4. Node.js 可执行文件和版本
#   5. Gradle 可执行文件和版本
#   6. Android SDK 目录结构
#   7. 软链接有效性
# 
# 输出格式:
#   显示每个组件的检查状态（✓ 或 ✗）
#   对于软链接，显示实际指向的目标
#   最后汇总检查结果
# 
# 自动修复:
#   - 如果环境变量未设置，会自动设置为默认值
#   - 如果 JAVA_HOME 无效，会尝试查找可用的 Java 安装
#   - 如果 PATH 缺少必要目录，会自动添加
# 
# 使用示例:
#   verify_environment
#   # 输出类似:
#   # ==========================================
#   # 验证环境设置
#   # ==========================================
#   # ✓ Java: /opt/java/current/bin/java
#   #   openjdk version "17.0.10" 2024-01-16
#   # ✓ Node.js: /opt/node/current/bin/node
#   #   v20.19.5
#   # ✓ Gradle: /opt/gradle/current/bin/gradle
#   #   Gradle 8.14.2
#   # ✓ Android SDK: /opt/android-sdk
#   # ✓ 所有环境检查通过
# ============================================================================
verify_environment() {
  echo ""
  echo "=========================================="
  echo "验证环境设置"
  echo "=========================================="
  
  local failed=0
  
  # 确保环境变量已设置
  if [[ -z "${JAVA_HOME}" ]]; then
    export JAVA_HOME=/opt/java/current
  fi
  if [[ -z "${NODE_HOME}" ]]; then
    export NODE_HOME=/opt/node/current
  fi
  if [[ -z "${GRADLE_HOME}" ]]; then
    export GRADLE_HOME=/opt/gradle/current
  fi
  if [[ -z "${ANDROID_HOME}" ]]; then
    export ANDROID_HOME=/opt/android-sdk
  fi
  
  # 确保 PATH 包含所有必要的目录
  if [[ ":$PATH:" != *":/opt/java/current/bin:"* ]]; then
    export PATH="/opt/java/current/bin:$PATH"
  fi
  
  # 检查 Java
  if [[ -L "${JAVA_HOME}" ]]; then
    echo "  JAVA_HOME: $JAVA_HOME → $(readlink "$JAVA_HOME")"
  elif [[ -d "${JAVA_HOME}" ]]; then
    echo "  JAVA_HOME: $JAVA_HOME"
  else
    echo "  WARNING: JAVA_HOME points to invalid directory: $JAVA_HOME"
    # 尝试找到 Java
    local java_home_real=$(ls -1d /opt/java/jdk-* 2>/dev/null | tail -1)
    if [[ -n "$java_home_real" ]]; then
      export JAVA_HOME="$java_home_real"
      echo "  FIXED: JAVA_HOME = $java_home_real"
    fi
  fi
  
  if [[ -x "${JAVA_HOME}/bin/java" ]]; then
    echo "✓ Java: ${JAVA_HOME}/bin/java"
    "${JAVA_HOME}/bin/java" -version 2>&1 | head -1
  else
    echo "✗ Java: ${JAVA_HOME}/bin/java (不可用)"
    failed=$((failed + 1))
  fi
  
  # 检查 Node.js
  if [[ -L "${NODE_HOME}" ]]; then
    echo "  NODE_HOME: $NODE_HOME → $(readlink "$NODE_HOME")"
  fi
  
  if [[ -x "${NODE_HOME}/bin/node" ]]; then
    echo "✓ Node.js: ${NODE_HOME}/bin/node"
    "${NODE_HOME}/bin/node" --version
  else
    echo "✗ Node.js: ${NODE_HOME}/bin/node (不可用)"
    failed=$((failed + 1))
  fi
  
  # 检查 Gradle
  if [[ -L "${GRADLE_HOME}" ]]; then
    echo "  GRADLE_HOME: $GRADLE_HOME → $(readlink "$GRADLE_HOME")"
  fi
  
  if [[ -x "${GRADLE_HOME}/bin/gradle" ]]; then
    echo "✓ Gradle: ${GRADLE_HOME}/bin/gradle"
    "${GRADLE_HOME}/bin/gradle" --version 2>&1 | head -1
  else
    echo "✗ Gradle: ${GRADLE_HOME}/bin/gradle (不可用)"
    failed=$((failed + 1))
  fi
  
  # 检查 Android SDK
  if [[ -d "${ANDROID_HOME}/cmdline-tools/latest" ]]; then
    echo "✓ Android SDK: ${ANDROID_HOME}"
  else
    echo "✗ Android SDK: ${ANDROID_HOME} (不可用)"
    failed=$((failed + 1))
  fi
  
  # 检查环境变量
  echo ""
  echo "环境变量:"
  echo "  JAVA_HOME=${JAVA_HOME}"
  echo "  NODE_HOME=${NODE_HOME}"
  echo "  GRADLE_HOME=${GRADLE_HOME}"
  echo "  ANDROID_HOME=${ANDROID_HOME}"
  
  echo "=========================================="
  
  if [[ $failed -eq 0 ]]; then
    echo "✓ 所有环境检查通过"
    return 0
  else
    echo "✗ 部分环境检查失败 ($failed 个)"
    return 1
  fi
}

# ============================================================================
# 主流程
# ============================================================================

# 检查依赖命令
require_cmd tar
require_cmd unzip
require_cmd sed

# 应用预设配置
apply_preset

echo "=========================================="
echo "Cordova Environment Setup"
echo "=========================================="
echo "Profile: $PROFILE"
echo "Node.js: $NODE_VERSION"
echo "Java: ${JAVA_VERSION:-$JAVA_MAJOR (latest)}"
echo "Gradle: $GRADLE_VERSION"
echo "Build Tools: $BUILD_TOOLS_VERSION"
echo "Platform API: $PLATFORM_API"
echo "=========================================="

# 执行安装
install_node "$NODE_VERSION"
install_java "$JAVA_MAJOR" "$JAVA_VERSION"
install_gradle "$GRADLE_VERSION"
install_cmdline_tools "$CMDLINE_TOOLS_VERSION"

# 确保所有 "current" 软链接都正确指向（必须在设置环境变量之前）
echo "Setting up symlinks..."

# 调试：列出已安装的版本
echo "Checking installed versions..."
echo "  Java versions: $(ls -1d ${JAVA_ROOT}/jdk-* 2>/dev/null || echo 'none')"
echo "  Node versions: $(ls -1d ${NODE_ROOT}/node-v* 2>/dev/null || echo 'none')"
echo "  Gradle versions: $(ls -1d ${GRADLE_ROOT}/gradle-* 2>/dev/null || echo 'none')"

# 创建 Java 软链接 - 优先使用具体版本，回退到主版本
java_target=""
if [[ -n "$JAVA_VERSION" ]]; then
  java_target="${JAVA_ROOT}/jdk-${JAVA_VERSION%%+*}"
  if [[ ! -d "$java_target" ]]; then
    echo "WARNING: Java target directory not found: $java_target"
    echo "Available: $(ls -1d ${JAVA_ROOT}/jdk-* 2>/dev/null | tail -1)"
    java_target=$(ls -1d ${JAVA_ROOT}/jdk-* 2>/dev/null | tail -1)
  fi
else
  java_target="${JAVA_ROOT}/jdk-${JAVA_MAJOR}"
  if [[ ! -d "$java_target" ]]; then
    java_target=$(ls -1d ${JAVA_ROOT}/jdk-* 2>/dev/null | tail -1)
  fi
fi

if [[ -n "$java_target" && -d "$java_target" ]]; then
  $SUDO ln -sfn "$java_target" "${JAVA_ROOT}/current"
  echo "  Java: $java_target"
fi

# 创建 Node 软链接 - 使用实际安装的版本
node_target="${NODE_ROOT}/node-v${NODE_VERSION}"
if [[ ! -d "$node_target" ]]; then
  node_target=$(ls -1d ${NODE_ROOT}/node-v* 2>/dev/null | tail -1)
fi
if [[ -n "$node_target" && -d "$node_target" ]]; then
  $SUDO ln -sfn "$node_target" "${NODE_ROOT}/current"
  echo "  Node: $node_target"
fi

# 创建 Gradle 软链接
gradle_target="${GRADLE_ROOT}/gradle-${GRADLE_VERSION}"
if [[ ! -d "$gradle_target" ]]; then
  gradle_target=$(ls -1d ${GRADLE_ROOT}/gradle-* 2>/dev/null | tail -1)
fi
if [[ -n "$gradle_target" && -d "$gradle_target" ]]; then
  $SUDO ln -sfn "$gradle_target" "${GRADLE_ROOT}/current"
  echo "  Gradle: $gradle_target"
fi

echo "Symlinks created successfully"

# 设置必要的环境变量供后续使用（特别是 sdkmanager）
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export JAVA_HOME=/opt/java/current
export NODE_HOME=/opt/node/current
export GRADLE_HOME=/opt/gradle/current
export PATH="${JAVA_HOME}/bin:${NODE_HOME}/bin:${GRADLE_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# 验证 JAVA_HOME 是否有效
if [[ ! -d "$JAVA_HOME" ]]; then
  echo "ERROR: JAVA_HOME is still invalid after creating symlink: $JAVA_HOME" >&2
  echo "Available Java directories:" >&2
  ls -la /opt/java/ >&2 || true
  exit 5
fi

echo "Environment variables configured"
echo "  JAVA_HOME=$JAVA_HOME"
echo "  NODE_HOME=$NODE_HOME"
echo "  GRADLE_HOME=$GRADLE_HOME"

install_android_packages "$BUILD_TOOLS_VERSION" "$PLATFORM_API"

# 验证软链接
echo ""
echo "Verifying symlinks..."
for link in "${JAVA_ROOT}/current" "${NODE_ROOT}/current" "${GRADLE_ROOT}/current"; do
  if [[ -L "$link" ]]; then
    target=$(readlink "$link")
    if [[ -d "$target" ]]; then
      echo "  ✓ $link → $target"
    else
      echo "  ✗ $link → $target (target not found!)"
    fi
  else
    echo "  ✗ Symlink not found: $link"
  fi
done

write_global_env

# 验证环境设置
verify_environment

echo ""
echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="
echo ""
echo "要激活环境变量，请运行以下命令之一:"
echo ""
echo "1. 当前会话（立即生效）:"
echo "   source /etc/profile.d/cordova-env.sh"
echo ""
echo "2. 新终端会话:"
echo "   打开新的 Terminal/Shell 窗口"
echo ""
echo "验证安装:"
echo "   java -version"
echo "   node --version"
echo "   gradle --version"
echo ""
echo "=========================================="
