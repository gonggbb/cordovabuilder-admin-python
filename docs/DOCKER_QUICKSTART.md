# 🚀 CordovaBuilder Admin Python - Docker 快速启动指南

## 📋 前置检查清单

在启动之前，请确保：

- [ ] Docker Desktop 已安装并运行
- [ ] Docker Compose 可用（Docker Desktop 自带）
- [ ] `dist/` 目录存在（前端已打包）
- [ ] `.env.docker` 文件存在（已配置）
- [ ] 80 端口未被占用

## ⚡ 一键启动（推荐）

### Windows 用户
```bash
start.bat
```
选择选项 **1** - 构建并启动服务

### Linux/macOS 用户
```bash
chmod +x start.sh
./start.sh
```
选择选项 **1** - 构建并启动服务

## 🔧 手动启动

### 方式 1: Docker Compose（推荐）

```bash
# 1. 构建镜像
docker-compose build

# 2. 后台启动服务
docker-compose up -d

# 3. 查看日志
docker-compose logs -f app-service

# 4. 停止服务
docker-compose down
```

### 方式 2: 直接使用 Docker

```bash
# 1. 构建镜像
docker build -t cordovabuilder-python:latest .

# 2. 运行容器
docker run -d \
  --name cordovabuilder-python-app \
  -p 80:80 \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/downloads/node:/tmp/node-install \
  -v $(pwd)/downloads/java:/tmp/java-install \
  -v $(pwd)/downloads/gradle:/tmp/gradle-install \
  -v $(pwd)/downloads/cmdline:/tmp/cmdline-tools-install \
  --restart unless-stopped \
  cordovabuilder-python:latest

# 3. 查看日志
docker logs -f cordovabuilder-python-app

# 4. 停止容器
docker stop cordovabuilder-python-app
docker rm cordovabuilder-python-app
```

## 🌐 访问服务

启动成功后，可以通过以下地址访问：

| 服务 | 地址 | 说明 |
|------|------|------|
| 前端页面 | http://localhost/ | 主界面 |
| API 文档 | http://localhost/api/docs | Swagger UI |
| ReDoc 文档 | http://localhost/api/redoc | ReDoc 文档 |
| 健康检查 | http://localhost/health | 健康状态 |
| OpenAPI JSON | http://localhost/openapi.json | API 定义 |

## 📊 常用管理命令

### 查看服务状态
```bash
docker-compose ps
```

### 查看实时日志
```bash
docker-compose logs -f app-service
```

### 重启服务
```bash
docker-compose restart
```

### 进入容器内部
```bash
docker exec -it cordovabuilder-python-app bash
```

### 查看容器资源使用
```bash
docker stats cordovabuilder-python-app
```

### 清理所有资源
```bash
# 停止并删除容器、网络
docker-compose down

# 同时删除镜像和卷（谨慎使用）
docker-compose down --rmi all --volumes
```

## 🔍 故障排查

### 问题 1: 端口 80 被占用

**症状**: 启动失败，提示端口已被占用

**解决**:
```bash
# 查找占用 80 端口的进程
netstat -ano | findstr :80  # Windows
lsof -i :80                  # Linux/macOS

# 修改 docker-compose.yml 的端口映射
ports:
  - "8080:80"  # 改为其他端口
```

### 问题 2: dist/ 目录不存在

**症状**: 构建失败，提示找不到 dist/ 目录

**解决**:
```bash
# 创建空的 dist 目录（临时方案）
mkdir dist
echo "<html><body>Frontend not built</body></html>" > dist/index.html

# 或者先构建前端项目
cd ../frontend
npm run build
```

### 问题 3: 健康检查失败

**症状**: 容器启动但健康检查一直失败

**解决**:
```bash
# 等待更长时间（启动期可能需要 30-60 秒）
sleep 60

# 检查容器日志
docker-compose logs app-service

# 手动测试健康检查
docker exec cordovabuilder-python-app curl http://localhost/health

# 检查 Nginx 和 FastAPI 是否运行
docker exec cordovabuilder-python-app ps aux
```

### 问题 4: 卷挂载权限问题

**症状**: 无法写入 workspace 或 downloads 目录

**解决**:
```bash
# Windows: 在 Docker Desktop 中配置文件共享
# Settings -> Resources -> File Sharing -> 添加项目目录

# Linux/macOS: 修复目录权限
sudo chown -R $USER:$USER ./workspace ./downloads
chmod -R 755 ./workspace ./downloads
```

### 问题 5: 下载速度慢或失败

**症状**: 下载 JDK、Android SDK 等工具超时

**解决**:
```bash
# 检查网络连接
docker exec cordovabuilder-python-app ping google.com

# 配置代理（如果需要）
# 在 docker-compose.yml 中添加环境变量
environment:
  - HTTP_PROXY=http://your-proxy:port
  - HTTPS_PROXY=http://your-proxy:port
```

## 📝 配置文件说明

### 核心配置文件

| 文件 | 用途 | 修改后需要 |
|------|------|-----------|
| `Dockerfile` | 镜像构建规则 | 重新构建镜像 |
| `docker-compose.yml` | 容器编排配置 | 重启服务 |
| `.env.docker` | Docker 环境变量 | 重新构建或重启 |
| `.dockerignore` | 构建时忽略的文件 | 重新构建镜像 |

### 重要环境变量

```env
# 服务器配置
PORT=3000                    # FastAPI 内部端口
LOGURU_LEVEL=INFO            # 日志级别

# 工作目录
WORKSPACE_DIR=/workspace     # 工作区路径

# 下载目录（与 docker-compose 卷挂载一致）
NODE_INSTALL_DIR=/tmp/node-install
JAVA_INSTALL_DIR=/tmp/java-install
GRADLE_INSTALL_DIR=/tmp/gradle-install
CMDLINE_TOOLS_INSTALL_DIR=/tmp/cmdline-tools-install

# 安装目录
NODE_HOME=/opt/node
JAVA_HOME=/opt/java/jdk-17
GRADLE_HOME=/opt/gradle
ANDROID_HOME=/opt/android-sdk
```

## 🎯 下一步

启动成功后，你可以：

1. **访问 API 文档**: http://localhost/api/docs
2. **测试 API 接口**: 使用 Swagger UI 进行接口测试
3. **查看日志**: `docker-compose logs -f`
4. **部署前端**: 将前端构建产物放到 `dist/` 目录
5. **配置生产环境**: 修改 `.env.docker` 中的配置

## 📚 相关文档

- [Docker 配置检查报告](DOCKER_CONFIG_CHECK.md) - 详细的配置检查和修复说明
- [README.md](README.md) - 项目总体介绍
- [USE.md](USE.md) - 使用指南

---

**最后更新**: 2026-04-13  
**维护者**: CordovaBuilder Team