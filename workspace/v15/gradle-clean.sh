#!/bin/bash
# File Name: gradle-clean.sh
# Desc: 清理 Gradle 缓存和构建产物，解决文件锁定问题
#############################################

set -euo pipefail

PROJECT_DIR="${1:-/workspace/v15}"

echo "======================================================"
echo "🧹 清理 Gradle 缓存和构建产物"
echo "======================================================"
echo ""

cd "$PROJECT_DIR" || { echo "❌ 无法进入项目目录: $PROJECT_DIR"; exit 1; }

echo "📋 当前目录: $(pwd)"
echo ""

# 0. 终止可能的 Java/Gradle 进程（避免文件锁定）
echo "[INFO] Step 0/5: 检查并终止 Java/Gradle 进程..."
TERMINATED_COUNT=0

# 方法 1: 使用 killall（如果可用）
if command -v killall >/dev/null 2>&1; then
  if killall -9 java 2>/dev/null; then
    echo "[OK] 已终止所有 java 进程"
    TERMINATED_COUNT=$((TERMINATED_COUNT + 1))
  fi
  if killall -9 gradle 2>/dev/null; then
    echo "[OK] 已终止所有 gradle 进程"
    TERMINATED_COUNT=$((TERMINATED_COUNT + 1))
  fi
fi

# 方法 2: 使用 killall5（发送信号给所有进程，谨慎使用）
if command -v killall5 >/dev/null 2>&1; then
  echo "[WARN] 检测到 killall5 命令，但不建议使用（会影响所有进程）"
  echo "[INFO] 将使用 /proc 文件系统精确查找 Java/Gradle 进程"
fi

# 方法 3: 通过 /proc 查找并终止（Docker 容器兼容，推荐）
if [ -d "/proc" ]; then
  for pid in $(ls /proc 2>/dev/null | grep -E '^[0-9]+$'); do
    # 跳过当前进程和 init 进程
    if [ "$pid" = "$$" ] || [ "$pid" = "1" ]; then
      continue
    fi
    
    if [ -f "/proc/$pid/cmdline" ] && grep -q "java\|gradle" "/proc/$pid/cmdline" 2>/dev/null; then
      CMDLINE=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ' | head -c 100)
      echo "[WARN] 发现 Java/Gradle 进程 PID=$pid: $CMDLINE"
      if kill -9 "$pid" 2>/dev/null; then
        echo "[OK] 已终止进程 PID=$pid"
        TERMINATED_COUNT=$((TERMINATED_COUNT + 1))
      else
        echo "[WARN] 无法终止进程 PID=$pid（可能无权限）"
      fi
    fi
  done
fi

if [ $TERMINATED_COUNT -eq 0 ]; then
  echo "[INFO] 未发现运行中的 Java/Gradle 进程"
else
  echo "[OK] 共终止 $TERMINATED_COUNT 个进程"
  sleep 1  # 等待进程完全退出
fi

# 1. 清理 APK 输出目录（解决文件锁定问题）
echo ""
echo "[INFO] Step 1/5: 清理 APK 输出目录..."
if [ -d "platforms/android/app/build/outputs/apk/release" ]; then
  # 先修改文件权限为可写
  find platforms/android/app/build/outputs/apk/release -type f -exec chmod +w {} \; 2>/dev/null || true
  rm -rf platforms/android/app/build/outputs/apk/release
  echo "[OK] 已删除 platforms/android/app/build/outputs/apk/release"
else
  echo "[INFO] APK 输出目录不存在，跳过"
fi

# 2. 清理项目级 Gradle 缓存
echo ""
echo "[INFO] Step 2/5: 清理项目 Gradle 缓存..."
if [ -d "platforms/android/.gradle" ]; then
  rm -rf platforms/android/.gradle
  echo "[OK] 已删除 platforms/android/.gradle"
else
  echo "[INFO] 项目 Gradle 缓存不存在，跳过"
fi

# 3. 清理 build 目录（可选，彻底清理）
echo ""
echo "[INFO] Step 3/5: 清理构建中间文件..."
if [ -d "platforms/android/app/build" ]; then
  find platforms/android/app/build -type f -exec chmod +w {} \; 2>/dev/null || true
  rm -rf platforms/android/app/build
  echo "[OK] 已删除 platforms/android/app/build"
else
  echo "[INFO] build 目录不存在，跳过"
fi

# 4. 清理用户级 Gradle 缓存（谨慎使用）
echo ""
echo "[INFO] Step 4/5: 清理用户 Gradle 缓存..."
if [ -d "$HOME/.gradle/caches" ]; then
  rm -rf "$HOME/.gradle/caches"
  echo "[OK] 已删除 ~/.gradle/caches"
else
  echo "[INFO] 用户 Gradle 缓存不存在，跳过"
fi

# 5. 检查磁盘空间
echo ""
echo "[INFO] Step 5/5: 检查磁盘空间..."
DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}')
DISK_AVAIL=$(df -h . | tail -1 | awk '{print $4}')
echo "[OK] 磁盘使用率: $DISK_USAGE, 可用空间: $DISK_AVAIL"

echo ""
echo "======================================================"
echo "[OK] 清理完成！"
echo "======================================================"
echo ""
echo "提示: 现在可以重新执行构建命令："
echo "  bash apk-automatic-v2.sh \\"
echo "    --project-dir $PROJECT_DIR \\"
echo "    --keystore-path <密钥库路径> \\"
echo "    --key-alias <密钥别名> \\"
echo "    --keystore-password <密码> \\"
echo "    --key-password <密码>"
echo ""
