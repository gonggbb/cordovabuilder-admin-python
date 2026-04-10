#!/usr/bin/env bash
# ============================================================================
# Android SDK Manager Script
# ============================================================================
# 用于管理 Android SDK 组件的 Bash 脚本
# 支持下载、安装、列出组件、接受许可证等操作
#
# 使用方法:
#   ./android_sdk_manager.sh --info                    # 查看 SDK 信息
#   ./android_sdk_manager.sh --download [--version X]  # 下载 cmdline-tools
#   ./android_sdk_manager.sh --install <archive>       # 安装 cmdline-tools
#   ./android_sdk_manager.sh --install-packages <pkgs> # 安装 SDK 组件
#   ./android_sdk_manager.sh --list-packages           # 列出已安装的组件
#   ./android_sdk_manager.sh --accept-licenses         # 接受所有许可证
# ============================================================================

set -euo pipefail

# ============================================================================
# 配置
# ============================================================================
ANDROID_SDK_ROOT="${ANDROID_HOME:-/opt/android-sdk}"
CMDLINE_TOOLS_DIR="${ANDROID_SDK_ROOT}/cmdline-tools"
SDKMANAGER="${CMDLINE_TOOLS_DIR}/latest/bin/sdkmanager"

# ============================================================================
# 帮助信息
# ============================================================================
usage() {
  cat >&2 <<'EOF'
Usage:
  android_sdk_manager.sh [OPTIONS]

Options:
  --info                    Show SDK information
  --download [--version X]  Download cmdline-tools (default: latest)
  --install <archive>       Install cmdline-tools from archive
  --install-packages <pkgs> Install SDK packages
  --list-packages           List installed packages
  --accept-licenses         Accept all SDK licenses
  -h, --help                Show this help message

Examples:
  android_sdk_manager.sh --info
  android_sdk_manager.sh --download --version 14742923
  android_sdk_manager.sh --install /tmp/cmdline-tools.zip
  android_sdk_manager.sh --install-packages "platform-tools" "platforms;android-33"
  android_sdk_manager.sh --list-packages
  android_sdk_manager.sh --accept-licenses
EOF
  exit 2
}

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

# 检测是否需要 sudo
if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# ============================================================================
# 功能函数
# ============================================================================

# 显示 SDK 信息
show_info() {
  echo "Android SDK Information"
  echo "======================"
  echo "ANDROID_HOME: ${ANDROID_SDK_ROOT}"
  echo "CMDLINE_TOOLS_DIR: ${CMDLINE_TOOLS_DIR}"
  
  if [[ -x "${SDKMANAGER}" ]]; then
    echo "SDK Manager: Installed"
    echo "Version: $("${SDKMANAGER}" --version 2>&1 || echo 'unknown')"
  else
    echo "SDK Manager: Not installed"
  fi
  
  echo ""
  echo "Installed packages:"
  if [[ -x "${SDKMANAGER}" ]]; then
    "${SDKMANAGER}" --list --verbose 2>/dev/null | grep "Installed" || echo "  (none)"
  else
    echo "  (SDK Manager not available)"
  fi
}

# 下载 cmdline-tools
download_cmdline_tools() {
  local version="${1:-latest}"
  local cache_dir="/tmp/cmdline-tools-download"
  local output_file
  
  if [[ "$version" == "latest" ]]; then
    version="14742923"  # 默认最新版本号
  fi
  
  output_file="${cache_dir}/commandlinetools-linux-${version}_latest.zip"
  local url="https://dl.google.com/android/repository/commandlinetools-linux-${version}_latest.zip"
  
  echo "Downloading cmdline-tools version ${version}..."
  echo "URL: ${url}"
  echo "Output: ${output_file}"
  
  mkdir -p "$cache_dir"
  
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --retry-delay 2 -o "$output_file" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$output_file" "$url"
  else
    echo "Neither curl nor wget is available." >&2
    exit 3
  fi
  
  echo "Download completed: ${output_file}"
}

# 安装 cmdline-tools
install_cmdline_tools() {
  local archive="$1"
  local latest_dir="${CMDLINE_TOOLS_DIR}/latest"
  
  if [[ ! -f "$archive" ]]; then
    echo "Archive not found: ${archive}" >&2
    exit 4
  fi
  
  echo "Installing cmdline-tools from: ${archive}"
  
  $SUDO mkdir -p "${CMDLINE_TOOLS_DIR}"
  $SUDO rm -rf "${latest_dir}"
  
  local extract_dir="/tmp/cmdline-tools-extract"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"
  
  unzip -q "$archive" -d "$extract_dir"
  
  if [[ -d "${extract_dir}/cmdline-tools" ]]; then
    $SUDO mv "${extract_dir}/cmdline-tools" "${latest_dir}"
  else
    $SUDO mv "$extract_dir" "${latest_dir}"
  fi
  
  $SUDO chmod -R 755 "${latest_dir}/bin"
  
  echo "Installation completed: ${latest_dir}"
}

# 安装 SDK 组件
install_packages() {
  local packages=("$@")
  
  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No packages specified" >&2
    exit 5
  fi
  
  if [[ ! -x "${SDKMANAGER}" ]]; then
    echo "SDK Manager not found. Please install cmdline-tools first." >&2
    exit 5
  fi
  
  echo "Installing packages: ${packages[*]}"
  
  export ANDROID_HOME="${ANDROID_SDK_ROOT}"
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
  
  "${SDKMANAGER}" "${packages[@]}"
  
  echo "Packages installed successfully"
}

# 列出已安装的包
list_packages() {
  if [[ ! -x "${SDKMANAGER}" ]]; then
    echo "SDK Manager not found. Please install cmdline-tools first." >&2
    exit 5
  fi
  
  echo "Installed packages:"
  "${SDKMANAGER}" --list --verbose 2>/dev/null | grep "Installed"
}

# 接受所有许可证
accept_licenses() {
  if [[ ! -x "${SDKMANAGER}" ]]; then
    echo "SDK Manager not found. Please install cmdline-tools first." >&2
    exit 5
  fi
  
  echo "Accepting all SDK licenses..."
  
  export ANDROID_HOME="${ANDROID_SDK_ROOT}"
  export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
  
  yes | "${SDKMANAGER}" --licenses >/dev/null 2>&1 || true
  
  echo "All licenses accepted"
}

# ============================================================================
# 主流程
# ============================================================================

# 检查依赖命令
require_cmd unzip

# 解析命令行参数
if [[ $# -eq 0 ]]; then
  usage
fi

ACTION=""
VERSION=""
ARCHIVE=""
PACKAGES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info)
      ACTION="info"
      shift
      ;;
    --download)
      ACTION="download"
      shift
      # 可选的版本参数
      if [[ $# -gt 0 && "$1" == "--version" ]]; then
        shift
        VERSION="${1:-latest}"
        shift
      fi
      ;;
    --install)
      ACTION="install"
      shift
      ARCHIVE="${1:-}"
      if [[ -z "$ARCHIVE" ]]; then
        echo "Error: --install requires an archive path" >&2
        usage
      fi
      shift
      ;;
    --install-packages)
      ACTION="install-packages"
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        PACKAGES+=("$1")
        shift
      done
      ;;
    --list-packages)
      ACTION="list-packages"
      shift
      ;;
    --accept-licenses)
      ACTION="accept-licenses"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

# 执行操作
case "$ACTION" in
  info)
    show_info
    ;;
  download)
    download_cmdline_tools "$VERSION"
    ;;
  install)
    install_cmdline_tools "$ARCHIVE"
    ;;
  install-packages)
    install_packages "${PACKAGES[@]}"
    ;;
  list-packages)
    list_packages
    ;;
  accept-licenses)
    accept_licenses
    ;;
  *)
    echo "Unknown action: ${ACTION}" >&2
    usage
    ;;
esac
