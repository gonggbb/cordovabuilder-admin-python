#!/bin/bash
# File Name: apk-init.sh
# Version: V2.0-Simplified
# Author: gamesg
# Organization: github.com/gonggbb
# Desc: Cordova Android 环境初始化脚本 (简化版)
#############################################
set -euo pipefail

echo "======================================================"
echo "Cordova Android Build Environment Check & Init"
echo "======================================================"

# ============================================================================
# Step 1: 检查环境变量
# ============================================================================
echo ""
echo "Step 1: 检查环境变量"

MISSING_ENV=false

check_env() {
  local var_name=$1
  local var_value="${!var_name:-}"
  if [ -z "$var_value" ]; then
    echo "[ERROR] 环境变量 $var_name 未设置"
    MISSING_ENV=true
  else
    echo "[OK] $var_name = $var_value"
  fi
}

check_env "JAVA_HOME"
check_env "ANDROID_SDK_ROOT"
check_env "GRADLE_HOME"

if [ "$MISSING_ENV" = true ]; then
  echo ""
  echo "[ERROR] 必要环境变量缺失，请设置 JAVA_HOME, ANDROID_SDK_ROOT, GRADLE_HOME"
  exit 1
fi

echo "[OK] 环境变量检查通过"

# ============================================================================
# Step 2: 检查必要命令
# ============================================================================
echo ""
echo "Step 2: 检查必要命令"

MISSING_CMD=false

check_command() {
  local cmd=$1
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd = $(command -v "$cmd")"
  else
    echo "[ERROR] 命令 $cmd 不存在"
    MISSING_CMD=true
  fi
}

check_command "java"
check_command "javac"
check_command "gradle"
# cordova 可能在后续安装，这里只警告不强制退出，或者如果预期已安装则检查
if ! command -v cordova >/dev/null 2>&1; then
  echo "[WARN] cordova 命令未找到，将在后续步骤尝试安装"
else
  echo "[OK] cordova = $(command -v cordova)"
fi

if [ "$MISSING_CMD" = true ]; then
  echo ""
  echo "[ERROR] 缺少必要基础命令 (java/javac/gradle)，无法继续"
  exit 1
fi

# ============================================================================
# Step 3: 进入项目目录
# ============================================================================
echo ""
echo "Step 3: 进入项目目录"

PROJECT_DIR=${PROJECT_DIR:-/workspace}
if [ ! -d "$PROJECT_DIR" ]; then
  echo "[ERROR] 项目目录不存在: $PROJECT_DIR"
  exit 1
fi

cd "$PROJECT_DIR"
echo "[OK] 当前目录: $(pwd)"

# ============================================================================
# Step 4: 安装依赖和平台
# ============================================================================
echo ""
echo "Step 4: 安装依赖和平台"

# 安装 Cordova
if ! command -v cordova >/dev/null 2>&1; then
  echo "[INFO] 正在全局安装 Cordova..."
  npm -g install cordova
  echo "[OK] Cordova 安装完成"
else
  echo "[OK] Cordova 已安装"
fi

# 安装 npm 依赖
if [ -f package.json ]; then
  echo "[INFO] 检测到 package.json，安装 npm 依赖..."
  npm install --no-audit --no-fund
  echo "[OK] npm 依赖安装完成"
else
  echo "[WARN] 未检测到 package.json，跳过 npm 依赖安装"
fi

# 禁用 Cordova 遥测
export CORDOVA_TELEMETRY_OPT_OUT=true
echo "[OK] Cordova 遥测已禁用"

# 添加 Android 平台
echo "[INFO] 检查并添加 Android 平台..."
if cordova platform ls 2>/dev/null | grep -q "android.*installed" || cordova platform ls 2>/dev/null | grep -q "Installed platforms:"; then
  # 进一步确认 android 是否在已安装列表中
  if cordova platform ls 2>/dev/null | grep -E "^\s+android\s+" >/dev/null 2>&1; then
    echo "[OK] Android 平台已安装，跳过"
  else
    echo "[INFO] Android 平台未完全安装，重新添加..."
    cordova platform add android --no-telemetry || {
      echo "[WARN] cordova platform add 执行失败，尝试继续..."
    }
    echo "[OK] Android 平台添加完成"
  fi
else
  echo "[INFO] 添加 Android 平台..."
  cordova platform add android --no-telemetry || {
    echo "[WARN] cordova platform add 执行失败，尝试继续..."
  }
  echo "[OK] Android 平台添加完成"
fi

echo ""
echo "======================================================"
echo "[OK] 环境初始化完成"
echo "======================================================"
