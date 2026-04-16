# CordovaBuilder Admin - Python 版本

## 项目概述

CordovaBuilder Admin 是一个基于 FastAPI 的后端服务，用于管理和配置 Cordova/Android 应用构建所需的基础环境工具。

**核心特性**:

- 🚀 自动化环境管理：一键安装 Node.js、Java JDK、Gradle、Android SDK
- 📦 预设配置：提供多种 Cordova 版本组合的预设配置
- 🔧 灵活定制：支持自定义各组件版本
- 🐳 跨平台支持：可在 Linux、Docker 环境中运行
- 🎯 脚本驱动：所有安装逻辑通过 Bash 脚本实现，易于维护

## 架构设计

### 基于脚本的架构

本项目采用**脚本驱动的架构模式**：

```
┌─────────────────────────────────────────┐
│         FastAPI Application             │
│  (app/main.py)                          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         API Routes                      │
│  (app/api/v1/*.py)                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│      Service Layer                      │
│  (app/services/*.py)                    │
│  - script_executor_service.py           │
│  - env_config_service.py                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│      Bash Scripts                       │
│  (scripts/*.sh)                         │
│  - setup_cordova_env.sh                 │
│  - download_file.sh                     │
└─────────────────────────────────────────┘
```

**优势**:

1. **单一事实来源**: 所有业务逻辑在 Bash 脚本中实现
2. **易于测试**: 可独立测试脚本和 API
3. **灵活部署**: 脚本可在 Docker 和本地环境通用
4. **便于维护**: 修改脚本即可更新功能，无需修改 Python 代码

## 快速开始

### 前置要求

- Python 3.10+
- Poetry
- Bash
- curl 或 wget
- sudo 权限（用于安装到 /opt/）

### 启动服务

```bash
cd server && poetry install

# 开发模式（自动重载）
poetry run uvicorn app.main:app --reload --port 3000

# 生产模式
poetry run uvicorn app.main:app --host 0.0.0.0 --port 3000
```

### 访问 API 文档

- Swagger UI: http://localhost:3000/docs
- ReDoc: http://localhost:3000/redoc

## 预设配置

| 配置名 | Cordova | cordova-android | Node.js | Java | Gradle | Build Tools | Platform |
| ------ | ------- | --------------- | ------- | ---- | ------ | ----------- | -------- |
| ca11   | 12.x    | 11.x            | 18.20.8 | 11   | 7.4.2  | 32.0.0      | 32       |
| ca12   | 12.x    | 12.x            | 18.20.8 | 17   | 7.6    | 33.0.2      | 33       |
| ca13   | 12.x    | 13.x            | 18.20.8 | 17   | 8.6    | 34.0.0      | 34       |
| ca14   | 13.x    | 14.x            | 20.19.5 | 17   | 8.13   | 35.0.0      | 35       |
| ca15   | 13.x    | 15.x            | 20.19.5 | 17   | 8.14.2 | 36.0.0      | 36       |

## 安装目录

脚本会将工具安装到以下位置：

```
/opt/
├── node/
│   ├── node-v{version}/
│   └── current -> node-v{version}
├── java/
│   ├── jdk-{version}/
│   └── current -> jdk-{version}
├── gradle/
│   ├── gradle-{version}/
│   └── current -> gradle-{version}
└── android-sdk/
    ├── cmdline-tools/latest/
    ├── platform-tools/
    ├── platforms/android-{api}/
    └── build-tools/{version}/
```

## 环境变量

安装完成后，脚本会创建 `/etc/profile.d/cordova-env.sh` 文件，设置以下环境变量：

```bash
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export JAVA_HOME=/opt/java/current
export NODE_HOME=/opt/node/current
export GRADLE_HOME=/opt/gradle/current
export PATH="$JAVA_HOME/bin:$NODE_HOME/bin:$GRADLE_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```
