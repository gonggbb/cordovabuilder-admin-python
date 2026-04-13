#!/bin/bash
set -e

# 创建必要目录
mkdir -p /workspace /tmp/node-install /tmp/java-install /tmp/gradle-install /tmp/cmdline-tools-install

# 启动 Nginx
nginx -t && nginx

# 启动 FastAPI (监听所有接口，便于调试)
exec uvicorn app.main:app --host 0.0.0.0 --port 3000