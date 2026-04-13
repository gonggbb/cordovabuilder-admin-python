# Docker 配置快速参考

## ✅ 配置状态
**所有检查项已通过** - 可以安全构建和启动

---

## 🚀 快速启动

### 一键启动（推荐）
```bash
# Windows
start.bat

# Linux/macOS
chmod +x start.sh && ./start.sh
```

### Docker Compose
```bash
docker-compose up -d --build
```

---

## 🔑 关键配置对照

| 配置项 | 值 | 说明 |
|--------|-----|------|
| **外部端口** | 80 | Nginx 监听端口 |
| **内部端口** | 3000 | FastAPI 监听端口 |
| **工作区** | `/workspace` | 构建产物目录 |
| **Node 下载** | `/tmp/node-install` | Node.js 下载目录 |
| **Java 下载** | `/tmp/java-install` | JDK 下载目录 |
| **Gradle 下载** | `/tmp/gradle-install` | Gradle 下载目录 |
| **Android SDK** | `/tmp/cmdline-tools-install` | Android SDK 下载目录 |

---

## 🌐 访问地址

- **前端**: http://localhost/
- **API 文档**: http://localhost/api/docs
- **健康检查**: http://localhost/health

---

## 📋 常用命令

```bash
# 查看日志
docker-compose logs -f app-service

# 查看状态
docker-compose ps

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 进入容器
docker exec -it cordovabuilder-python-app bash

# 清理所有资源
docker-compose down --rmi all --volumes
```

---

## ⚠️ 注意事项

1. **前置条件**: 确保 `dist/` 目录存在
2. **端口占用**: 确保 80 端口未被占用
3. **权限问题**: 确保 `workspace` 和 `downloads` 有写权限
4. **网络要求**: 需要访问 Google、GitHub 等外部源

---

## 📄 相关文档

- [详细检查报告](DOCKER_IMAGE_CHECK_REPORT.md)
- [快速启动指南](DOCKER_QUICKSTART.md)
- [配置检查清单](DOCKER_CONFIG_CHECK.md)

---

**最后更新**: 2026-04-13