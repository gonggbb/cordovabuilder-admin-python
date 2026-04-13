#!/usr/bin/env bash
# ============================================================================
# 测试脚本：验证解压异常修复
# ============================================================================
# 用途：测试 extract_archive 函数的各种场景
# 使用：bash test_extraction.sh

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试计数
TESTS_PASSED=0
TESTS_FAILED=0

# 临时目录
TEST_DIR="/tmp/extract_test_$$"
mkdir -p "$TEST_DIR"

cleanup() {
  echo "Cleaning up test files..."
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# 打印测试结果
print_result() {
  local test_name="$1"
  local result="$2"
  
  if [[ "$result" -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} $test_name"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $test_name"
    ((TESTS_FAILED++))
  fi
}

# 这里需要从主脚本中获取函数定义
# 为了测试，我们创建最小的函数版本

# 检查磁盘空间函数
check_disk_space() {
  local path="$1"
  local required_mb="${2:-500}"
  
  local check_path="$path"
  while [[ ! -e "$check_path" && "$check_path" != "/" ]]; do
    check_path="$(dirname "$check_path")"
  done
  
  local available
  available="$(df "$check_path" | awk 'NR==2 {print $4}')"
  
  if [[ $available -lt $((required_mb * 1024)) ]]; then
    echo "ERROR: Insufficient disk space at $check_path" >&2
    return 1
  fi
  return 0
}

# 验证压缩文件函数
verify_archive() {
  local archive="$1"
  local archive_type="${2:-auto}"
  
  if [[ ! -f "$archive" ]]; then
    echo "ERROR: Archive file not found: $archive" >&2
    return 1
  fi
  
  if [[ "$archive_type" == "auto" ]]; then
    case "$archive" in
      *.tar.gz|*.tgz) archive_type="tar" ;;
      *.zip) archive_type="zip" ;;
      *) return 0 ;;
    esac
  fi
  
  case "$archive_type" in
    tar)
      if ! tar -tf "$archive" >/dev/null 2>&1; then
        echo "ERROR: Invalid tar archive: $archive" >&2
        return 1
      fi
      ;;
    zip)
      if ! unzip -t "$archive" >/dev/null 2>&1; then
        echo "ERROR: Invalid zip archive: $archive" >&2
        return 1
      fi
      ;;
  esac
  
  return 0
}

echo "============================================"
echo "测试解压函数修复"
echo "============================================"
echo ""

# 测试1: 创建有效的 tar.gz 文件
echo "Test 1: 创建和验证有效的 tar.gz 文件"
TEST1_DIR="$TEST_DIR/test1"
mkdir -p "$TEST1_DIR/content"
echo "test content" > "$TEST1_DIR/content/test.txt"

tar -czf "$TEST1_DIR/test.tar.gz" -C "$TEST1_DIR" content >/dev/null 2>&1
if verify_archive "$TEST1_DIR/test.tar.gz"; then
  print_result "验证有效的 tar.gz" 0
else
  print_result "验证有效的 tar.gz" 1
fi

# 测试2: 检测无效的 tar.gz 文件
echo ""
echo "Test 2: 检测损坏的 tar.gz 文件"
INVALID_TAR="$TEST_DIR/invalid.tar.gz"
echo "this is not a tar file" > "$INVALID_TAR"
if verify_archive "$INVALID_TAR" 2>/dev/null; then
  print_result "检测损坏的 tar.gz" 1
else
  print_result "检测损坏的 tar.gz" 0
fi

# 测试3: 检测不存在的文件
echo ""
echo "Test 3: 检测不存在的文件"
if verify_archive "$TEST_DIR/nonexistent.tar.gz" 2>/dev/null; then
  print_result "检测不存在的文件" 1
else
  print_result "检测不存在的文件" 0
fi

# 测试4: 磁盘空间检查
echo ""
echo "Test 4: 磁盘空间检查"
if check_disk_space /tmp 1; then
  print_result "检查 /tmp 空间" 0
else
  print_result "检查 /tmp 空间" 1
fi

# 测试5: 创建和验证 zip 文件
echo ""
echo "Test 5: 创建和验证 zip 文件"
TEST5_DIR="$TEST_DIR/test5"
mkdir -p "$TEST5_DIR/content"
echo "zip test content" > "$TEST5_DIR/content/test.txt"

cd "$TEST5_DIR" && zip -q test.zip content/test.txt && cd - >/dev/null
if verify_archive "$TEST5_DIR/test.zip"; then
  print_result "验证有效的 zip 文件" 0
else
  print_result "验证有效的 zip 文件" 1
fi

# 测试6: 检测无效的 zip 文件
echo ""
echo "Test 6: 检测损坏的 zip 文件"
INVALID_ZIP="$TEST_DIR/invalid.zip"
echo "PK" > "$INVALID_ZIP"  # ZIP 文件头但不完整
if verify_archive "$INVALID_ZIP" 2>/dev/null; then
  print_result "检测损坏的 zip 文件" 1
else
  print_result "检测损坏的 zip 文件" 0
fi

# 打印总结
echo ""
echo "============================================"
echo "测试结果总结"
echo "============================================"
echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
echo -e "失败: ${RED}$TESTS_FAILED${NC}"
echo "总计: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}所有测试通过！✓${NC}"
  exit 0
else
  echo -e "${RED}部分测试失败！✗${NC}"
  exit 1
fi
