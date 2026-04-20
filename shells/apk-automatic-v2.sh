#!/bin/bash
# File Name: apk-automatic-v2.sh
# Version: V2.0
# Author: gamesg
# Organization: github.com/gonggbb
# Desc: 自动化构建并签名 APK（主入口脚本）
#############################################

set -euo pipefail

# ============================================================================
# 参数解析
# ============================================================================
PROJECT_DIR=""
KEYSTORE_PATH=""
KEY_ALIAS=""
KEYSTORE_PASSWORD=""
KEY_PASSWORD=""

# 解析命令行参数
while [ $# -gt 0 ]; do
  case "$1" in
    --project-dir)
      PROJECT_DIR="$2"; shift 2 ;;
    --keystore-path)
      KEYSTORE_PATH="$2"; shift 2 ;;
    --key-alias)
      KEY_ALIAS="$2"; shift 2 ;;
    --keystore-password)
      KEYSTORE_PASSWORD="$2"; shift 2 ;;
    --key-password)
      KEY_PASSWORD="$2"; shift 2 ;;
    -h|--help)
      echo "======================================================"
      echo "Usage: apk-automatic-v2.sh [OPTIONS]"
      echo "======================================================"
      echo ""
      echo "必需参数:"
      echo "  --project-dir DIR       项目目录路径"
      echo "  --keystore-path FILE    密钥库文件路径"
      echo "  --key-alias ALIAS       密钥别名"
      echo "  --keystore-password PWD 密钥库密码"
      echo "  --key-password PWD      密钥密码"
      echo ""
      echo "注意:"
      echo "  本脚本会自动调用 apk-init.sh 和 apk-build-sign-v2.sh"
      echo "  请确保环境已正确配置（JAVA_HOME, ANDROID_SDK_ROOT 等）"
      echo ""
      echo "示例:"
      echo "  $0 \\"
      echo "    --project-dir /workspace/my-app \\"
      echo "    --keystore-path /workspace/keystores/release.keystore \\"
      echo "    --key-alias my-key \\"
      echo "    --keystore-password store123 \\"
      echo "    --key-password key123"
      echo ""
      exit 0
      ;;
    *)
      echo "❌ 未知参数: $1" >&2
      exit 1
      ;;
  esac
done

# ============================================================================
# 参数验证
# ============================================================================
MISSING_ARGS=0

if [ -z "$PROJECT_DIR" ]; then
  echo "❌ 缺少必需参数: --project-dir"
  MISSING_ARGS=1
fi

if [ -z "$KEYSTORE_PATH" ]; then
  echo "❌ 缺少必需参数: --keystore-path"
  MISSING_ARGS=1
fi

if [ -z "$KEY_ALIAS" ]; then
  echo "❌ 缺少必需参数: --key-alias"
  MISSING_ARGS=1
fi

if [ -z "$KEYSTORE_PASSWORD" ]; then
  echo "❌ 缺少必需参数: --keystore-password"
  MISSING_ARGS=1
fi

if [ -z "$KEY_PASSWORD" ]; then
  echo "❌ 缺少必需参数: --key-password"
  MISSING_ARGS=1
fi

if [ $MISSING_ARGS -eq 1 ]; then
  echo ""
  echo "使用 --help 查看帮助信息"
  exit 1
fi

# ============================================================================
# 导出环境变量供子脚本使用
# ============================================================================
export PROJECT_DIR="$PROJECT_DIR"
export KEYSTORE_PATH="$KEYSTORE_PATH"
export KEY_ALIAS="$KEY_ALIAS"
export KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD"
export KEY_PASSWORD="$KEY_PASSWORD"

# ============================================================================
# 确定脚本所在目录（用于定位子脚本）
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# 执行流程
# ============================================================================
echo "======================================================"
echo "🚀 Cordova APK 自动化构建与签名"
echo "======================================================"
echo ""
echo "📋 配置信息:"
echo "  项目目录: $PROJECT_DIR"
echo "  密钥库: $KEYSTORE_PATH"
echo "  密钥别名: $KEY_ALIAS"
echo ""

# Step 1: 环境初始化
echo "======================================================"
echo "Step 1/2: 环境初始化"
echo "======================================================"

INIT_SCRIPT="$SCRIPT_DIR/apk-init.sh"
if [ ! -f "$INIT_SCRIPT" ]; then
  echo "❌ 找不到初始化脚本: $INIT_SCRIPT"
  exit 1
fi

bash "$INIT_SCRIPT" || {
  echo ""
  echo "❌ 环境初始化失败，终止执行"
  exit 1
}
echo ""

# Step 2: 构建和签名
echo "======================================================"
echo "Step 2/2: 构建和签名"
echo "======================================================"

BUILD_SCRIPT="$SCRIPT_DIR/apk-build-sign-v2.sh"
if [ ! -f "$BUILD_SCRIPT" ]; then
  echo "❌ 找不到构建脚本: $BUILD_SCRIPT"
  exit 1
fi

bash "$BUILD_SCRIPT" || {
  echo ""
  echo "❌ 构建签名失败，终止执行"
  exit 1
}
echo ""

echo "======================================================"
echo "✅ 所有步骤完成！"
echo "======================================================"