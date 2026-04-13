#!/usr/bin/env bash
# ============================================================================
# Activate Cordova Build Environment
# ============================================================================
# 激活 Cordova 构建环境的便捷脚本
# 
# 使用方法:
#   source activate-cordova-env.sh
#
# 功能:
#   1. 加载环境变量配置
#   2. 验证所有工具是否可用
#   3. 显示工具版本信息

set -euo pipefail

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 环境变量配置文件
ENV_FILE="/etc/profile.d/cordova-env.sh"

# 检查配置文件是否存在
if [[ ! -f "$ENV_FILE" ]]; then
  echo -e "${RED}✗${NC} Environment configuration not found: $ENV_FILE"
  echo "Please run: sudo bash scripts/setup_cordova_env.sh --profile ca12"
  return 1 2>/dev/null || exit 1
fi

# 加载环境变量
source "$ENV_FILE"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Cordova Build Environment${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 验证和显示工具信息
show_tool_info() {
  local tool_name="$1"
  local exec_path="$2"
  local version_cmd="${3:-}"
  
  if [[ -x "$exec_path" ]]; then
    echo -e "${GREEN}✓${NC} $tool_name"
    echo "   Path: $exec_path"
    
    if [[ -n "$version_cmd" ]]; then
      if output=$($version_cmd 2>&1 | head -1); then
        echo "   $output"
      fi
    fi
  else
    echo -e "${RED}✗${NC} $tool_name"
    echo "   Path: $exec_path (NOT FOUND)"
  fi
  echo ""
}

# 显示各工具信息
show_tool_info "Java JDK" "${JAVA_HOME}/bin/java" "${JAVA_HOME}/bin/java -version"
show_tool_info "Node.js" "${NODE_HOME}/bin/node" "${NODE_HOME}/bin/node --version"
show_tool_info "Gradle" "${GRADLE_HOME}/bin/gradle" "${GRADLE_HOME}/bin/gradle --version"

# 检查 Android SDK
if [[ -d "${ANDROID_HOME}" ]]; then
  echo -e "${GREEN}✓${NC} Android SDK"
  echo "   Path: ${ANDROID_HOME}"
  echo ""
else
  echo -e "${RED}✗${NC} Android SDK"
  echo "   Path: ${ANDROID_HOME} (NOT FOUND)"
  echo ""
fi

# 显示环境变量
echo -e "${BLUE}Environment Variables:${NC}"
echo "   JAVA_HOME=${JAVA_HOME}"
echo "   NODE_HOME=${NODE_HOME}"
echo "   GRADLE_HOME=${GRADLE_HOME}"
echo "   ANDROID_HOME=${ANDROID_HOME}"
echo "   ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"
echo ""

# PATH 检查
echo -e "${BLUE}PATH Verification:${NC}"
for tool_dir in "${JAVA_HOME}/bin" "${NODE_HOME}/bin" "${GRADLE_HOME}/bin"; do
  if [[ ":$PATH:" == *":$tool_dir:"* ]]; then
    echo -e "   ${GREEN}✓${NC} $tool_dir is in PATH"
  else
    echo -e "   ${RED}✗${NC} $tool_dir is NOT in PATH"
  fi
done
echo ""

echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✓ Environment ready!${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Quick test commands:"
echo "   java -version"
echo "   node --version"
echo "   npm --version"
echo "   gradle --version"
