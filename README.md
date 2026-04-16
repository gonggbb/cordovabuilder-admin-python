根据当前项目结构，这是一个 **CordovaBuilder Admin Python 版本**的后端服务项目。以下是完整的目录结构概览：

## 📁 项目整体结构

```
cordovabuilder-admin-python/
├── server/                          # 后端服务主目录
│   ├── app/                         # FastAPI 应用代码
│   │   ├── api/v1/                  # API 路由层
│   │   │   └── environment.py       # 环境管理接口（唯一保留的API）
│   │   ├── services/                # 业务逻辑层
│   │   │   └── env_script_executor_service.py  # 脚本执行服务
│   │   ├── configs/                 # 配置文件
│   │   │   └── env_presets.json     # 环境预设配置
│   │   ├── __init__.py
│   │   └── main.py                  # FastAPI 应用入口
│   ├── scripts/                     # Shell 脚本（核心逻辑）
│   │   └── setup_cordova_env.sh     # Cordova 环境设置脚本
│   ├── downloads/                   # 下载文件存储目录
│   ├── logs/                        # 日志文件目录
│   ├── .env                         # 环境变量配置
│   ├── pyproject.toml               # Poetry 依赖配置
│   ├── poetry.lock                  # 依赖锁定文件
│   ├── README.md                    # 项目说明文档
│   └── start-container.sh           # 容器启动脚本
│
├── shells/                          # 构建相关脚本 v2 版本脚本
│   ├── sdk-check.sh                 # SDK 检查脚本
│   ├── apk-automatic-v2.sh
│   ├── apk-build-sign-v2.sh
│   └── apk-init.sh
│
├── workspace/                       # 工作空间（Cordova 项目）
│   ├── v12/                         # v12 版本示例项目
│   │   ├── www/                     # Web 资源
│   │   ├── config.xml
│   │   ├── package.json
│   │   └── package-lock.json
│   └── v15/                         # v15 版本示例项目
│       ├── www/
│       ├── build.json
│       ├── config.xml
│       ├── package.json
│       └── package-lock.json
│
├── docs/                            # 文档目录（18个文档文件）
│   ├── COMPLETE_FIX_SUMMARY.md
│   ├── DOCKERFILE_SIMPLIFICATION.md
│   ├── ENVIRONMENT_API.md
│   ├── QUICKSTART.md
│   └── ... (其他文档)
│
├── client/                          # 客户端
├── Dockerfile                       # Docker 镜像构建文件
├── docker-compose.yml               # Docker Compose 配置
├── .gitignore                       # Git 忽略配置
├── .dockerignore                    # Docker 忽略配置
└── USE.md                           # 使用说明文档
```

## 🎯 核心架构特点

### 1. **分层架构**

- **API 层**: `server/app/api/v1/environment.py` - 提供 RESTful 接口
- **服务层**: `server/app/services/env_script_executor_service.py` - 调用 Shell 脚本
- **脚本层**: `server/scripts/setup_cordova_env.sh` - 核心业务逻辑实现

### 2. **技术栈**

- **Web 框架**: FastAPI + Uvicorn
- **依赖管理**: Poetry
- **部署方式**: Docker + Docker Compose
- **Python 版本**: 3.13

### 3. **关键功能模块**

- ✅ 环境配置管理（CRUD）
- ✅ Cordova 环境自动化设置
- ✅ 多版本支持（v12, v15）
- ✅ APK 构建与签名脚本

### 4. **设计模式**

采用 **"脚本承载核心逻辑，API 负责调度"** 的模式：

- 所有下载、安装、配置逻辑在 Bash 脚本中实现
- Python 服务层仅通过 `subprocess` 异步调用脚本
- 确保单一事实来源，便于维护和测试

激活环境变量：

```bash
source /etc/profile.d/cordova-env.sh
```

## Docker 部署

### 构建镜像

```bash
docker build -t cordovabuilder-python:latest .
```

### 运行容器

```bash
docker run -d \
  --name cordovabuilder-python-api \
  -p 3000:3000 \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/downloads:/downloads \
  cordovabuilder-python:latest
```

### 使用 Docker Compose

```bash
docker-compose up -d
```

## 测试

### 运行 API 测试

```bash
# 确保服务已启动
poetry run uvicorn app.main:app --reload --port 3000

# 运行测试脚本
python tests/test_environment_api.py
```

### 运行单元测试

```bash
poetry run pytest
```

## 开发指南

### 添加新的预设配置

1. 编辑 `scripts/setup_cordova_env.sh`
2. 在 `apply_preset()` 函数中添加新的 case 分支
3. 更新 `app/api/v1/environment.py` 中的 `get_presets()` 函数

### 修改安装逻辑

直接编辑 `scripts/setup_cordova_env.sh`，无需修改 Python 代码。

### 调试脚本

```bash
# 启用详细输出
bash -x scripts/setup_cordova_env.sh --profile ca12

# 或直接执行
sudo ./scripts/setup_cordova_env.sh --help
```
