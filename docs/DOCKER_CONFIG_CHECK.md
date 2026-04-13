# Docker 配置检查与修复报告

## 📋 检查日期
2026-04-13

## ✅ 已修复的问题

### 1. 缺少 curl 命令
**问题**: HEALTHCHECK 使用 `curl` 但 Dockerfile 未安装  
**修复**: 在 `apt-get install` 中添加 `curl`  
**状态**: ✅ 已修复

### 2. 路径配置不一致（严重）
**问题**: 
- docker-compose.yml 挂载到 `/tmp/*-install`
- 应用代码默认使用相对路径 `./downloads/*`
- 导致卷挂载失效，文件保存到错误位置

**修复**:
- ✅ 更新 `.env.docker` 添加所有必需的环境变量
- ✅ 确保环境变量值与 docker-compose 卷挂载路径一致
- ✅ 添加 WORKSPACE_DIR、NODE_HOME、JAVA_HOME 等完整配置

**配置对照表**:

| 配置项 | docker-compose 挂载路径 | .env.docker 配置 | 应用代码读取 |
|--------|----------------------|-----------------|------------|
| Node.js 下载 | `./downloads/node:/tmp/node-install` | `NODE_INSTALL_DIR=/tmp/node-install` | `os.getenv('NODE_INSTALL_DIR')` |
| Java 下载 | `./downloads/java:/tmp/java-install` | `JAVA_INSTALL_DIR=/tmp/java-install` | `os.getenv('JAVA_INSTALL_DIR')` |
| Gradle 下载 | `./downloads/gradle:/tmp/gradle-install` | `GRADLE_INSTALL_DIR=/tmp/gradle-install` | `os.getenv('GRADLE_INSTALL_DIR')` |
| Android SDK 下载 | `./downloads/cmdline:/tmp/cmdline-tools-install` | `CMDLINE_TOOLS_INSTALL_DIR=/tmp/cmdline-tools-install` | `os.getenv('CMDLINE_TOOLS_INSTALL_DIR')` |
| 工作区 | `./workspace:/workspace` | `WORKSPACE_DIR=/workspace` | `os.getenv('WORKSPACE_DIR')` |

### 3. 启动脚本优化
**改进**:
- ✅ 添加目录存在性检查和自动创建
- ✅ 显示详细的目录结构信息
- ✅ 添加 Nginx 健康检查
- ✅ 使用 `exec` 确保信号正确传递

## 🔍 配置一致性验证

### Dockerfile 配置
```dockerfile
✅ EXPOSE 80
✅ HEALTHCHECK 使用 curl（已安装）
✅ COPY .env.docker .env
✅ COPY dist/ /var/www/html/
✅ Nginx 反向代理到 127.0.0.1:3000
✅ 启动脚本同时运行 Nginx 和 Uvicorn
```

### docker-compose.yml 配置
```yaml
✅ ports: "80:80"
✅ environment: PORT=3000, LOGURU_LEVEL=INFO
✅ volumes: 所有下载目录和工作区目录
✅ healthcheck: curl -f http://localhost/health
✅ restart: unless-stopped
✅ networks: cordovabuilder-network
```

### .env.docker 配置
```env
✅ PORT=3000
✅ LOGURU_LEVEL=INFO
✅ WORKSPACE_DIR=/workspace
✅ NODE_INSTALL_DIR=/tmp/node-install
✅ JAVA_INSTALL_DIR=/tmp/java-install
✅ GRADLE_INSTALL_DIR=/tmp/gradle-install
✅ CMDLINE_TOOLS_INSTALL_DIR=/tmp/cmdline-tools-install
✅ NODE_HOME=/opt/node
✅ JAVA_HOME=/opt/java/jdk-17
✅ GRADLE_HOME=/opt/gradle
✅ ANDROID_HOME=/opt/android-sdk
```

## 🚀 启动流程

### 方式 1: Docker Compose（推荐）
```bash
# 构建并启动
docker-compose up -d --build

# 查看日志
docker-compose logs -f app-service

# 停止
docker-compose down
```

### 方式 2: 直接使用 Docker
```bash
# 构建镜像
docker build -t cordovabuilder-python:latest .

# 运行容器
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
```

## 🌐 访问地址

- **前端页面**: http://localhost/
- **API 文档**: http://localhost/api/docs
- **健康检查**: http://localhost/health
- **ReDoc 文档**: http://localhost/api/redoc

## ⚠️ 注意事项

### 1. 前置条件
- ✅ 确保 `dist/` 目录存在（前端已打包）
- ✅ 确保 `.env.docker` 文件存在
- ✅ 确保 `scripts/` 目录包含所有必需的 Bash 脚本
- ✅ 确保 Docker 和 Docker Compose 已安装

### 2. 端口冲突
- 确保主机 80 端口未被占用
- 如需修改端口，调整 docker-compose.yml 的 ports 配置

### 3. 权限问题
- 确保 `workspace` 和 `downloads` 目录有写权限
- Windows 用户可能需要配置 Docker Desktop 的文件共享

### 4. 网络要求
- 需要访问外部源下载工具包：
  - Google (Android SDK)
  - GitHub (Gradle)
  - Adoptium (JDK)
  - Node.js 官网

### 5. 数据持久化
- `workspace` 和 `downloads` 目录通过卷挂载持久化
- 容器重启后数据不会丢失
- 清理时使用 `docker-compose down --volumes` 会删除卷数据

## 🔧 故障排查

### 问题 1: 容器启动失败
```bash
# 查看详细日志
docker-compose logs app-service

# 检查容器状态
docker-compose ps
```

### 问题 2: 健康检查失败
```bash
# 等待启动期（10秒）后再检查
sleep 15
curl http://localhost/health

# 查看容器日志
docker logs cordovabuilder-python-app
```

### 问题 3: 卷挂载无效
```bash
# 检查容器内的目录
docker exec -it cordovabuilder-python-app ls -la /tmp/
docker exec -it cordovabuilder-python-app ls -la /workspace/

# 确认环境变量
docker exec -it cordovabuilder-python-app env | grep INSTALL_DIR
```

### 问题 4: API 无法访问
```bash
# 检查 Nginx 是否运行
docker exec -it cordovabuilder-python-app nginx -t

# 检查 FastAPI 是否监听 3000 端口
docker exec -it cordovabuilder-python-app netstat -tlnp | grep 3000

# 测试内部连接
docker exec -it cordovabuilder-python-app curl http://127.0.0.1:3000/health
```

## 📝 配置文件清单

| 文件 | 用途 | 版本控制 |
|------|------|---------|
| `Dockerfile` | 镜像构建配置 | ✅ 提交 |
| `docker-compose.yml` | 容器编排配置 | ✅ 提交 |
| `.env.docker` | Docker 环境配置 | ✅ 提交 |
| `.env` | 本地开发配置 | ❌ 忽略 |
| `.dockerignore` | Docker 构建忽略文件 | ✅ 提交 |
| `.gitignore` | Git 忽略文件 | ✅ 提交 |

## ✨ 优化建议

### 已完成
- ✅ 添加 curl 支持健康检查
- ✅ 统一路径配置
- ✅ 完善启动脚本
- ✅ 添加 .dockerignore

### 待优化（可选）
- [ ] 添加多阶段构建缓存优化
- [ ] 使用 BuildKit 加速构建
- [ ] 添加 Prometheus 监控指标
- [ ] 实现日志轮转和归档
- [ ] 添加资源限制（CPU/内存）

---

**报告生成时间**: 2026-04-13  
**配置状态**: ✅ 所有关键问题已修复，可以正常构建和启动