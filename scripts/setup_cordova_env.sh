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
CMDLINE_TOOLS_VERSION="14742923"
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
apply_preset() {
  case "$PROFILE" in
    ca11)
      NODE_VERSION="${NODE_VERSION:-18.20.8}"
      JAVA_MAJOR="${JAVA_MAJOR:-11}"
      JAVA_VERSION="${JAVA_VERSION:-}" # latest 11
      GRADLE_VERSION="${GRADLE_VERSION:-7.4.2}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-32.0.0}"
      PLATFORM_API="${PLATFORM_API:-32}"
      ;;
    ca12)
      NODE_VERSION="${NODE_VERSION:-18.20.8}"
      JAVA_MAJOR="${JAVA_MAJOR:-17}"
      JAVA_VERSION="${JAVA_VERSION:-17.0.10+7}"
      GRADLE_VERSION="${GRADLE_VERSION:-7.6}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-33.0.2}"
      PLATFORM_API="${PLATFORM_API:-33}"
      ;;
    ca14)
      NODE_VERSION="${NODE_VERSION:-20.19.5}"
      JAVA_MAJOR="${JAVA_MAJOR:-17}"
      JAVA_VERSION="${JAVA_VERSION:-17.0.10+7}"
      GRADLE_VERSION="${GRADLE_VERSION:-8.13}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-35.0.0}"
      PLATFORM_API="${PLATFORM_API:-35}"
      ;;
    ca15)
      NODE_VERSION="${NODE_VERSION:-20.19.5}"
      JAVA_MAJOR="${JAVA_MAJOR:-17}"
      JAVA_VERSION="${JAVA_VERSION:-17.0.10+7}"
      GRADLE_VERSION="${GRADLE_VERSION:-8.14.2}"
      BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-36.0.0}"
      PLATFORM_API="${PLATFORM_API:-36}"
      ;;
  esac
}

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

if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# ============================================================================
# 工具函数
# ============================================================================

# 检查命令是否存在
require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 3
  fi
}

# 下载文件 (如果不存在)
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

# 检测系统架构
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

# 检测 JDK 架构
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

# 检查磁盘空间
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

# 验证压缩文件
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

# 通用解压函数
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

# 获取最新 Temurin JDK URL
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

# 根据版本号获取 Temurin JDK URL
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

# 安装 Node.js
# 下载并安装指定版本的 Node.js，配置软链接指向当前版本
# 
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
  $SUDO ln -sfn "$install_dir" "${NODE_ROOT}/current"
}

# 安装 Gradle
# 下载并安装指定版本的 Gradle 构建工具
# 
# 参数:
#   $1 - version: Gradle 版本号（例如: "8.14.2"）
# 
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
    extracted="$(tar -tzf "$archive" 2>/dev/null | grep -o '^[^/]\+' | sort -u | head -n1)"
    
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
# 
# 参数:
#   $1 - version: cmdline-tools 版本号（例如: "14742923"）
# 
# 返回值:
#   无显式返回值，失败时通过 exit code 退出
install_cmdline_tools() {
  local version="$1"
  local archive="${CMDLINE_CACHE}/commandlinetools-linux-${version}_latest.zip"
  local url="https://dl.google.com/android/repository/commandlinetools-linux-${version}_latest.zip"
  local latest_dir="${ANDROID_SDK_ROOT}/cmdline-tools/latest"
  local sdkmanager_path="${latest_dir}/bin/sdkmanager"

  download_if_missing "$url" "$archive"

  if [[ ! -x "$sdkmanager_path" ]]; then
    echo "Installing Android cmdline-tools -> ${latest_dir}"
    $SUDO mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"
    $SUDO rm -rf "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
    
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
    
    # 移动至目标位置
    if [[ -d /tmp/cmdline-tools-extract/cmdline-tools ]]; then
      if ! $SUDO mv /tmp/cmdline-tools-extract/cmdline-tools "${latest_dir}"; then
        echo "ERROR: Failed to move cmdline-tools" >&2
        exit 5
      fi
    else
      if ! $SUDO mv /tmp/cmdline-tools-extract "${latest_dir}"; then
        echo "ERROR: Failed to move cmdline-tools" >&2
        exit 5
      fi
    fi
    
    # 设置执行权限
    $SUDO chmod -R 755 "${latest_dir}/bin"
    
    # 清理临时目录
    $SUDO rm -rf /tmp/cmdline-tools-extract
    
    echo "Android cmdline-tools installation completed successfully"
  else
    echo "Android cmdline-tools already installed: ${latest_dir}"
  fi
}

# 获取 sdkmanager 路径
sdkmanager_cmd() {
  echo "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
}

# 安装 Android SDK 组件
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

# 写入全局环境变量配置
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

# 验证环境设置
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
