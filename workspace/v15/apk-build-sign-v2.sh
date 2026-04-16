#!/bin/bash
# File Name: apk-build-sign-v2.sh
# Version: V2.0
# Author: gamesg
# Organization: github.com/gonggbb
# Desc: APK 打包和签名
#############################################

# ============================================================================
# 检查必需的环境变量
# ============================================================================
echo "======================================================"
echo "🔑 APK 构建和签名"
echo "======================================================"
echo ""
echo "📋 检查环境变量..."

if [ -z "$KEYSTORE_PATH" ] || [ -z "$KEY_ALIAS" ] || [ -z "$KEYSTORE_PASSWORD" ] || [ -z "$KEY_PASSWORD" ]; then
  echo "❌ 签名所需的环境变量未全部设置"
  echo "请确保以下变量已设置："
  echo "  KEYSTORE_PATH, KEY_ALIAS, KEYSTORE_PASSWORD, KEY_PASSWORD"
  echo "------------------------------------------------------"
  exit 1
fi

echo "✅ 环境变量检查通过"
echo "  KEYSTORE_PATH: $KEYSTORE_PATH"
echo "  KEY_ALIAS: $KEY_ALIAS"
echo ""

# ============================================================================
# 进入项目目录
# ============================================================================
echo "======================================================"
echo "Step 1/4: 进入项目目录"
echo "======================================================"

PROJECT_DIR=${PROJECT_DIR:-/workspace}

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ 项目目录不存在: $PROJECT_DIR"
  exit 1
fi

cd "$PROJECT_DIR" || { echo "❌ 无法进入项目目录: $PROJECT_DIR"; exit 1; }
echo "✅ 当前目录: $(pwd)"
echo ""

# ============================================================================
# 检查必要命令
# ============================================================================
echo "======================================================"
echo "Step 2/4: 检查必要命令"
echo "======================================================"

if command -v apksigner >/dev/null 2>&1; then
  echo "✅ apksigner = $(command -v apksigner)"
  apksigner --version 2>/dev/null || true
else
  echo "⚠️  apksigner 不在 PATH 中"
  if [ -n "${ANDROID_BUILD_TOOLS:-}" ]; then
    echo "ℹ️  ANDROID_BUILD_TOOLS: $ANDROID_BUILD_TOOLS"
  else
    echo "⚠️  未设置 ANDROID_BUILD_TOOLS"
  fi
fi
echo ""

# ============================================================================
# 执行构建和签名
# ============================================================================
echo "======================================================"
echo "Step 3/4: 执行构建和签名"
echo "======================================================"

# # 清理旧的构建产物（避免文件锁定问题）
# echo "[INFO] 清理旧的构建产物..."
# if [ -d "platforms/android/app/build/outputs/apk/release" ]; then
#   rm -rf platforms/android/app/build/outputs/apk/release || {
#     echo "[WARN] 无法删除旧的 APK 输出目录，尝试强制清理..."
#     find platforms/android/app/build/outputs/apk/release -type f -exec chmod +w {} \; 2>/dev/null || true
#     rm -rf platforms/android/app/build/outputs/apk/release || {
#       echo "[ERROR] 仍然无法删除输出目录，可能存在文件占用"
#       echo "建议: 检查是否有其他进程正在使用该目录"
#       exit 1
#     }
#   }
#   echo "[OK] 已清理旧的 APK 输出目录"
# else
#   echo "[INFO] 输出目录不存在，无需清理"
# fi

echo ""
echo "⚙️  使用 Cordova 命令行进行 APK 签名..."
echo "这可能需要几分钟时间，请耐心等待..."
echo ""

cordova build android --release -- --packageType=apk \
  --keystore="$KEYSTORE_PATH" \
  --keystoreType=PKCS12 \
  --storePassword="$KEYSTORE_PASSWORD" \
  --alias="$KEY_ALIAS" \
  --password="$KEY_PASSWORD"

echo ""

# ============================================================================
# 验证签名结果
# ============================================================================
echo "======================================================"
echo "Step 4/4: 验证签名结果"
echo "======================================================"

APK_SIGNED=$(find platforms/android -type f -name "app-release.apk" 2>/dev/null | head -n 1)

if [ -n "$APK_SIGNED" ]; then
  FULL_PATH="$(pwd)/$APK_SIGNED"
  
  echo "✅ APK 签名完成"
  echo "📦 签名文件: $APK_SIGNED"
  echo "📍 完整路径: $FULL_PATH"
  
  if [ -f "$FULL_PATH" ]; then
    APK_SIZE=$(du -h "$FULL_PATH" | cut -f1)
    echo "📏 文件大小: $APK_SIZE"
  fi
else
  echo "❌ 未找到已签名的 APK 文件"
  echo "请检查上方构建日志确认是否有错误"
  exit 1
fi

echo ""
echo "======================================================"
echo "🎉 APK 签名流程完成"
echo "======================================================"
echo ""