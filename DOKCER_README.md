# CordovaBuilder Admin Python

自动化 Cordova 移动应用环境配置与 APK 构建管理系统。基于 FastAPI + Docker，简化开发环境配置、依赖管理和 APK 构建流程。

## 快速开始

### 方式一：Docker 命令

```bash
# 拉取镜像
docker pull gamesg/cordovabuilder-admin-python:v1.0.0

# 运行容器
docker run -d \
  --name cordovabuilder-admin \
  -p 80:80 \
  -p 3000:3000 \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/downloads/node:/tmp/node-install \
  -v $(pwd)/downloads/java:/tmp/java-install \
  -v $(pwd)/downloads/gradle:/tmp/gradle-install \
  -v $(pwd)/downloads/cmdline:/tmp/cmdline-tools-install \
  gamesg/cordovabuilder-admin-python:v1.0.0
```

### 方式二：Docker Compose

**1. 创建 docker-compose.yml**

```yaml
version: '3.8'

services:
  cordovabuilder-admin:
    image: gamesg/cordovabuilder-admin-python:v1.0.0
    container_name: cordovabuilder-python-admin
    ports:
      - '80:80'
      - '3000:3000'
    volumes:
      - ./workspace:/workspace
      - ./downloads/node:/tmp/node-install
      - ./downloads/java:/tmp/java-install
      - ./downloads/gradle:/tmp/gradle-install
      - ./downloads/cmdline:/tmp/cmdline-tools-install
    restart: unless-stopped
```

**2. 启动服务**

```bash
# 启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止
docker-compose down
```

## 访问服务

- **前端界面**: http://${IP}
- **API 接口**: http://${IP}:3000/api/v1
- **API 文档**: http://${IP}:3000/docs

## 常用命令

```bash
# 容器管理
docker start cordovabuilder-admin          # 启动容器
docker stop cordovabuilder-admin           # 停止容器
docker restart cordovabuilder-admin        # 重启容器
docker logs -f cordovabuilder-admin        # 查看日志

# 进入容器
docker exec -it cordovabuilder-admin bash

# 查看容器状态
docker ps
docker inspect cordovabuilder-admin

apk-automatic-v2.sh --project-dir /workspace/v15 --keystore-path /workspace/v15/myApp15.p12 --key-alias myApp15 --keystore-password 123456 --key-password 123456
```

## 功能特性

- 一键配置 JDK、Android SDK、Node.js 等开发环境
- 自动化 APK 构建与签名
- 多版本 Cordova 环境支持 (v12/v15)
- RESTful API 管理环境配置

## 技术栈

Server : Python 3.13 | FastAPI | Docker | Nginx | Bash
Web : Vue3.5+ | Typescript | vite8+
