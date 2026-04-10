# 快速启动指南

## 5分钟快速开始

### 1. 安装依赖

```bash
# 进入项目目录
cd cordovabuilder-admin-python

# 安装 Python 依赖
poetry install
```

### 2. 配置环境（可选）

```bash
# 如果需要自定义配置，复制并编辑 .env 文件
cp .env.example .env
```

> **注意**: 默认配置已足够使用，此步骤可跳过。

### 3. 启动服务

```bash
# 开发模式（推荐）
poetry run uvicorn app.main:app --reload --port 3000
```

看到以下输出表示启动成功：
```
INFO:     CordovaBuilder Admin API 启动中...
INFO:     服务端口: 3000
SUCCESS:  CordovaBuilder Admin API 启动成功！
INFO:     API 文档地址: http://localhost:3000/docs
```

### 4. 访问 API 文档

打开浏览器访问：
- **Swagger UI**: http://localhost:3000/docs
- **ReDoc**: http://localhost:3000/redoc

### 5. 测试 API

#### 方法 1: 使用 Swagger UI

1. 访问 http://localhost:3000/docs
2. 展开 `/api/environment/presets` 接口
3. 点击 "Try it out" → "Execute"
4. 查看返回的预设配置列表

#### 方法 2: 使用 curl

```bash
# 获取预设配置列表
curl http://localhost:3000/api/environment/presets | jq

# 设置环境（需要 sudo 权限和较长时间）
curl -X POST http://localhost:3000/api/environment/setup \
  -H "Content-Type: application/json" \
  -d '{"profile": "ca12"}'
```

#### 方法 3: 运行测试脚本

```bash
python tests/test_environment_api.py
```

## 常用操作

### 查看可用配置

```bash
curl http://localhost:3000/api/environment/presets | jq '.presets | keys'
```

返回：
```json
[
  "ca11",
  "ca12",
  "ca14",
  "ca15"
]
```

### 使用预设配置安装环境

```bash
# 使用 ca12 预设（推荐）
curl -X POST http://localhost:3000/api/environment/setup \
  -H "Content-Type: application/json" \
  -d '{"profile": "ca12"}'
```

> **注意**: 
> - 此操作需要 **sudo 权限**
> - 需要 **5-10GB 磁盘空间**
> - 可能需要 **30-60 分钟**（取决于网络速度）
> - 建议在生产环境中使用 Docker 部署

### 自定义版本安装

```bash
# 基于 ca12 预设，但使用不同版本的 Node.js 和 Gradle
curl -X POST http://localhost:3000/api/environment/setup \
  -H "Content-Type: application/json" \
  -d '{
    "profile": "ca12",
    "node_version": "20.19.5",
    "gradle_version": "8.14.2"
  }'
```

### 直接执行脚本（推荐用于调试）

```bash
# 查看帮助
sudo ./scripts/setup_cordova_env.sh --help

# 使用预设配置
sudo ./scripts/setup_cordova_env.sh --profile ca12

# 自定义配置
sudo ./scripts/setup_cordova_env.sh \
  --node 20.19.5 \
  --java-major 17 \
  --gradle 8.14.2 \
  --build-tools 36.0.0 \
  --platform 36
```

## 验证安装

安装完成后，检查各组件是否正确安装：

```bash
# 激活环境变量
source /etc/profile.d/cordova-env.sh

# 检查 Node.js
node --version
npm --version

# 检查 Java
java -version
javac -version

# 检查 Gradle
gradle --version

# 检查 Android SDK
sdkmanager --list
adb version
```

## Docker 部署（推荐）

### 构建镜像

```bash
docker build -t cordovabuilder-python:latest .
```

### 运行容器

```bash
docker run -d \
  --name cordovabuilder-api \
  -p 3000:3000 \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/downloads:/downloads \
  cordovabuilder-python:latest
```

### 使用 Docker Compose

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 在容器中执行脚本

```bash
# 进入容器
docker exec -it cordovabuilder-api bash

# 执行安装脚本
./scripts/setup_cordova_env.sh --profile ca12

# 退出容器
exit
```

## 故障排查

### 问题 1: 服务无法启动

**症状**: `poetry run uvicorn` 报错

**解决**:
```bash
# 检查 Python 版本
python --version  # 需要 3.10+

# 重新安装依赖
poetry install

# 检查端口是否被占用
lsof -i :3000
```

### 问题 2: API 返回 500 错误

**症状**: 调用 `/api/environment/setup` 返回错误

**解决**:
```bash
# 查看详细错误信息
curl -X POST http://localhost:3000/api/environment/setup \
  -H "Content-Type: application/json" \
  -d '{"profile": "ca12"}' | jq '.detail'

# 检查脚本是否有执行权限
ls -la scripts/setup_cordova_env.sh
chmod +x scripts/setup_cordova_env.sh

# 手动执行脚本查看错误
sudo ./scripts/setup_cordova_env.sh --profile ca12
```

### 问题 3: 下载速度慢或失败

**症状**: 安装过程中卡在下载步骤

**解决**:
```bash
# 检查网络连接
ping nodejs.org
ping github.com

# 配置代理（如果需要）
export http_proxy=http://your-proxy:port
export https_proxy=http://your-proxy:port

# 重试安装
sudo ./scripts/setup_cordova_env.sh --profile ca12
```

### 问题 4: 权限不足

**症状**: `Permission denied` 错误

**解决**:
```bash
# 使用 sudo 执行
sudo ./scripts/setup_cordova_env.sh --profile ca12

# 或者修改安装目录权限
sudo chown -R $USER:$USER /opt/node /opt/java /opt/gradle /opt/android-sdk
```

### 问题 5: 磁盘空间不足

**症状**: `No space left on device` 错误

**解决**:
```bash
# 检查磁盘空间
df -h

# 清理旧的下载文件
rm -rf /tmp/node-install/*
rm -rf /tmp/java-install/*
rm -rf /tmp/gradle-install/*
rm -rf /tmp/cmdline-tools-install/*

# 或者清理整个 downloads 目录
rm -rf ./downloads/*
```

## 下一步

- 📖 阅读 [完整文档](README.md)
- 📚 查看 [API 文档](docs/ENVIRONMENT_API.md)
- 🔧 了解 [项目优化详情](PROJECT_OPTIMIZATION.md)
- 💡 查看 [常见问题](#故障排查)

## 获取帮助

如果遇到问题：

1. 查看日志输出
2. 检查 [故障排查](#故障排查) 部分
3. 查看 API 响应中的错误信息
4. 提交 Issue 到项目仓库

---

**祝您使用愉快！** 🎉