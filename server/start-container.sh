#!/bin/bash
# 脚本终止，退出码非零
set -e


# 创建必要目录
mkdir -p /workspace /tmp/node-install /tmp/java-install /tmp/gradle-install /tmp/cmdline-tools-install

# 启动 Nginx
nginx -t && nginx

# 切换到应用代码目录启动 FastAPI（确保 Python 能找到 app 模块）
cd /app

# ASGI (Asynchronous Server Gateway Interface) 服务器
# 启动 FastAPI (监听所有接口，便于调试)
exec uvicorn app.main:app --host 0.0.0.0 --port 3000