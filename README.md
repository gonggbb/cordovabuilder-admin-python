## 项目整体结构

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
├── shells/                          # 构建相关脚本 v2 版本脚本 /user/local/bin/
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

```

## 技术栈

- **Web 框架**: FastAPI + Uvicorn
- **依赖管理**: Poetry
- **部署方式**: Docker + Docker Compose
- **Python 版本**: 3.13

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

## 使用 Docker Compose

```bash
docker-compose up -d

# 确保服务已启动
# poetry run uvicorn app.main:app --reload --port 3000
```

## 🚀 快速开始

<video controls width="100%">
  <source src="https://raw.githubusercontent.com/gonggbb/cordovabuilder-admin-python/main/Video%20Project%203.mp4" type="video/mp4">
  您的浏览器不支持 HTML5 视频。
</video>
