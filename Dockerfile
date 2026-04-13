# ============================================
# CordovaBuilder Admin Python - Docker 镜像
# ============================================
# 多阶段构建，优化镜像大小

# ============================================
# 阶段 1: 构建依赖
# ============================================
FROM python:3.13-slim AS builder

# 设置工作目录
WORKDIR /build

# 安装 Poetry
RUN pip install --no-cache-dir poetry

# 复制依赖配置文件
COPY pyproject.toml poetry.lock* ./

# 安装依赖到虚拟环境
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root

# ============================================
# 阶段 2: 运行环境
# ============================================
FROM python:3.13-slim

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 安装系统级依赖（JDK, Android SDK, Nginx 等）
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    unzip \
    tar \
    xz-utils \
    ca-certificates \
    # Nginx (用于托管前端静态文件)
    nginx \
    # 中文语言环境支持
    locales \
    && sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    # 更新 SSL 证书
    && update-ca-certificates \
    # 清理缓存
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 设置中文语言环境
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 设置工作目录
WORKDIR /app

# 从构建阶段复制依赖
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 复制应用代码
COPY . .

# 复制 Docker 环境配置
COPY .env .env

# 复制前端静态文件到 Nginx 目录
COPY dist/ /var/www/html/

# 配置 Nginx
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    \
    # 前端静态文件 \
    location / { \
        root /var/www/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
    \
    # API 反向代理到 FastAPI \
    location /api/ { \
        proxy_pass http://127.0.0.1:3000/api/; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
    \
    # 健康检查接口 \
    location /health { \
        proxy_pass http://127.0.0.1:3000/health; \
        proxy_set_header Host $host; \
    } \
}' > /etc/nginx/sites-available/default

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# 复制启动脚本
COPY start-container.sh /start.sh
RUN chmod +x /start.sh

# 启动命令
CMD ["/start.sh"]
