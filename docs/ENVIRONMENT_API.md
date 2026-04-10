# 环境管理 API 文档

## 概述

环境管理 API 提供通过脚本自动化安装和配置 Cordova 构建环境的功能。所有操作都基于 `scripts/setup_cordova_env.sh` 脚本执行。

## 基础路径

```
/api/environment
```

## 预设配置

系统提供以下预设配置：

### ca11 - Cordova 12 + cordova-android 11.x
- Node.js: 18.20.8
- Java: 11 (latest)
- Gradle: 7.4.2
- Build Tools: 32.0.0
- Platform API: 32

### ca12 - Cordova 12 + cordova-android 12.x (默认)
- Node.js: 18.20.8
- Java: 17.0.10+7
- Gradle: 7.6
- Build Tools: 33.0.2
- Platform API: 33

### ca14 - Cordova 13 + cordova-android 14.x
- Node.js: 20.19.5
- Java: 17.0.10+7
- Gradle: 8.13
- Build Tools: 35.0.0
- Platform API: 35

### ca15 - Cordova 13 + cordova-android 15.x
- Node.js: 20.19.5
- Java: 17.0.10+7
- Gradle: 8.14.2
- Build Tools: 36.0.0
- Platform API: 36

## API 接口

### 1. 获取预设配置列表

**接口**: `GET /api/environment/presets`

**描述**: 获取所有可用的预设配置信息

**响应示例**:
```json
{
  "presets": {
    "ca11": {
      "name": "Cordova 12 + cordova-android 11.x",
      "node": "18.20.8",
      "java": "11 (latest)",
      "gradle": "7.4.2",
      "build_tools": "32.0.0",
      "platform_api": "32"
    },
    "ca12": {
      "name": "Cordova 12 + cordova-android 12.x",
      "node": "18.20.8",
      "java": "17.0.10+7",
      "gradle": "7.6",
      "build_tools": "33.0.2",
      "platform_api": "33"
    }
  },
  "default": "ca12"
}
```

---

### 2. 设置环境

**接口**: `POST /api/environment/setup`

**描述**: 调用脚本安装和配置完整的 Cordova 构建环境

**请求体**:
```json
{
  "profile": "ca12",
  "node_version": "18.20.8",
  "java_major": "17",
  "java_version": "17.0.10+7",
  "gradle_version": "7.6",
  "build_tools_version": "33.0.2",
  "platform_api": "33",
  "cmdline_version": "14742923"
}
```

**参数说明**:
- `profile` (必填): 预设配置名称 (ca11|ca12|ca14|ca15)
- 其他参数均为可选，用于覆盖预设配置

**成功响应**:
```json
{
  "success": true,
  "message": "Environment setup completed successfully",
  "output": "安装过程的输出日志..."
}
```

**失败响应**:
```json
{
  "detail": {
    "message": "Environment setup failed",
    "error": "错误信息",
    "output": "部分输出日志"
  }
}
```

**使用示例**:

使用预设配置：
```bash
curl -X POST http://localhost:3000/api/environment/setup \
  -H "Content-Type: application/json" \
  -d '{"profile": "ca12"}'
```

自定义配置：
```bash
curl -X POST http://localhost:3000/api/environment/setup \
  -H "Content-Type: application/json" \
  -d '{
    "profile": "ca12",
    "node_version": "20.19.5",
    "gradle_version": "8.14.2"
  }'
```

---

### 3. 切换环境

**接口**: `POST /api/environment/switch`

**描述**: 通过更新符号链接切换不同版本的工具（无需重新安装）

**注意**: 此功能尚未完全实现，当前建议使用完整的环境设置流程。

**请求体**:
```json
{
  "node_version": "20.19.5",
  "java_version": "17.0.10+7",
  "gradle_version": "8.14.2"
}
```

## 架构说明

### 设计原则

本项目采用**基于脚本的架构**：

1. **Bash 脚本层** (`scripts/`)
   - 实现所有下载、安装、配置逻辑
   - 支持命令行直接执行
   - 可在 Docker 和本地环境通用

2. **Python 服务层** (`app/services/`)
   - 通过 `subprocess` 异步调用 Bash 脚本
   - 不重复实现业务逻辑
   - 负责错误处理和结果封装

3. **API 路由层** (`app/api/v1/`)
   - 提供 RESTful 接口
   - 参数验证和格式化
   - 返回标准化响应

### 优势

- ✅ 单一事实来源：所有逻辑在脚本中实现
- ✅ 易于维护：修改脚本即可更新功能
- ✅ 灵活部署：支持 Docker 和本地运行
- ✅ 便于测试：可独立测试脚本和 API
- ✅ 环境变量切换：通过符号链接实现，无需重启服务

### 安装目录结构

```
/opt/
├── node/
│   ├── node-v18.20.8/
│   └── current -> node-v18.20.8
├── java/
│   ├── jdk-17.0.10+7/
│   └── current -> jdk-17.0.10+7
├── gradle/
│   ├── gradle-7.6/
│   └── current -> gradle-7.6
└── android-sdk/
    ├── cmdline-tools/
    │   └── latest/
    ├── platform-tools/
    ├── platforms/
    └── build-tools/
```

### 环境变量配置

脚本会自动创建 `/etc/profile.d/cordova-env.sh` 文件，设置以下环境变量：

```bash
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export JAVA_HOME=/opt/java/current
export NODE_HOME=/opt/node/current
export GRADLE_HOME=/opt/gradle/current
export PATH="$JAVA_HOME/bin:$NODE_HOME/bin:$GRADLE_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

激活环境变量：
```bash
source /etc/profile.d/cordova-env.sh
```

## 注意事项

1. **权限要求**: 脚本需要 sudo 权限来安装到 `/opt/` 目录
2. **网络要求**: 需要从多个源下载文件（Node.js、Adoptium、Google 等）
3. **磁盘空间**: 完整安装可能需要 5-10GB 空间
4. **超时设置**: API 默认超时为 1 小时，可根据需要调整
5. **幂等性**: 脚本支持重复执行，已安装的组件不会重复下载

## 故障排查

### 脚本执行失败

检查脚本输出中的错误信息：
```bash
# 查看 stderr 输出
curl -X POST http://localhost:3000/api/environment/setup \
  -H "Content-Type: application/json" \
  -d '{"profile": "ca12"}' | jq '.detail.error'
```

### 手动执行脚本

可以直接在服务器上执行脚本进行调试：
```bash
sudo ./scripts/setup_cordova_env.sh --profile ca12
```

### 检查安装状态

```bash
# 检查 Node.js
/opt/node/current/bin/node --version

# 检查 Java
/opt/java/current/bin/java -version

# 检查 Gradle
/opt/gradle/current/bin/gradle --version

# 检查 Android SDK
/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --list
```