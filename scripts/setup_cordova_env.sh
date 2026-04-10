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
    curl -fL --retry 3 --retry-delay 2 -o "$out" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$out" "$url"
  else
    echo "Neither curl nor wget is available." >&2
    exit 3
  fi
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
install_node() {
  local version="$1"
  local arch
  arch="$(detect_arch)"
  local archive="${NODE_CACHE}/node-v${version}-linux-${arch}.tar.xz"
  local url="https://nodejs.org/dist/v${version}/node-v${version}-linux-${arch}.tar.xz"
  local install_dir="${NODE_ROOT}/node-v${version}"

  download_if_missing "$url" "$archive"

  if [[ ! -d "$install_dir" ]]; then
    echo "Installing Node.js ${version} -> ${install_dir}"
    $SUDO mkdir -p "$NODE_ROOT"
    tar -xJf "$archive" -C /tmp
    $SUDO rm -rf "$install_dir"
    $SUDO mv "/tmp/node-v${version}-linux-${arch}" "$install_dir"
  else
    echo "Node.js already installed: $install_dir"
  fi

  $SUDO ln -sfn "$install_dir" "${NODE_ROOT}/current"
}

# 安装 Gradle
install_gradle() {
  local version="$1"
  local archive="${GRADLE_CACHE}/gradle-${version}-bin.zip"
  local url="https://services.gradle.org/distributions/gradle-${version}-bin.zip"
  local install_dir="${GRADLE_ROOT}/gradle-${version}"

  download_if_missing "$url" "$archive"

  if [[ ! -d "$install_dir" ]]; then
    echo "Installing Gradle ${version} -> ${install_dir}"
    $SUDO mkdir -p "$GRADLE_ROOT"
    $SUDO rm -rf "$install_dir"
    unzip -q "$archive" -d /tmp
    $SUDO mv "/tmp/gradle-${version}" "$install_dir"
  else
    echo "Gradle already installed: $install_dir"
  fi
}

# 安装 Java JDK
install_java() {
  local major="$1"
  local version="$2"  # empty means "latest for major"
  local url

  if [[ -n "$version" ]]; then
    url="$(get_temurin_url_from_version "$version")"
  else
    url="$(get_latest_temurin_url "$major")"
  fi

  local file_name
  file_name="$(basename "$url")"
  local archive="${JAVA_CACHE}/${file_name}"
  local install_dir

  if [[ -n "$version" ]]; then
    install_dir="${JAVA_ROOT}/jdk-${version%%+*}"
  else
    install_dir="${JAVA_ROOT}/jdk-${major}"
  fi

  download_if_missing "$url" "$archive"

  if [[ ! -d "$install_dir" ]]; then
    echo "Installing Java ${major} -> ${install_dir}"
    $SUDO mkdir -p "$JAVA_ROOT"
    $SUDO rm -rf "$install_dir"
    tar -xzf "$archive" -C /tmp
    local extracted
    extracted="$(tar -tzf "$archive" | head -n1 | cut -d/ -f1)"
    $SUDO mv "/tmp/${extracted}" "$install_dir"
  else
    echo "Java already installed: $install_dir"
  fi
}

# 安装 Android Command Line Tools
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
    unzip -q "$archive" -d /tmp/cmdline-tools-extract
    if [[ -d /tmp/cmdline-tools-extract/cmdline-tools ]]; then
      $SUDO mv /tmp/cmdline-tools-extract/cmdline-tools "${latest_dir}"
    else
      $SUDO mv /tmp/cmdline-tools-extract "${latest_dir}"
    fi
    $SUDO chmod -R 755 "${latest_dir}/bin"
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
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export JAVA_HOME=/opt/java/current
export NODE_HOME=/opt/node/current
export GRADLE_HOME=/opt/gradle/current
export PATH="$JAVA_HOME/bin:$NODE_HOME/bin:$GRADLE_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
EOF
  $SUDO chmod 644 "$env_file"
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

install_android_packages "$BUILD_TOOLS_VERSION" "$PLATFORM_API"

# Switch "current" symlinks based on chosen versions
if [[ -n "$JAVA_VERSION" ]]; then
  $SUDO ln -sfn "${JAVA_ROOT}/jdk-${JAVA_VERSION%%+*}" "${JAVA_ROOT}/current"
else
  $SUDO ln -sfn "${JAVA_ROOT}/jdk-${JAVA_MAJOR}" "${JAVA_ROOT}/current"
fi
$SUDO ln -sfn "${GRADLE_ROOT}/gradle-${GRADLE_VERSION}" "${GRADLE_ROOT}/current"

write_global_env

echo ""
echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="
echo "To activate the environment, run:"
echo "  source /etc/profile.d/cordova-env.sh"
echo "Or open a new terminal session."
echo "=========================================="
