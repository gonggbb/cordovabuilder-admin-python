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

# 安装系统级依赖（JDK, Android SDK 等）
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Java JDK 17
    openjdk-17-jdk-headless \
    # Android SDK 依赖
    wget \
    unzip \
    git \
    # 清理缓存
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 设置 Java 环境变量
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    PATH=$JAVA_HOME/bin:$PATH

# 创建必要的目录
RUN mkdir -p /opt/android-sdk/cmdline-tools \
    && mkdir -p /opt/node \
    && mkdir -p /opt/gradle \
    && mkdir -p /workspace \
    && mkdir -p /tmp/node-install \
    && mkdir -p /tmp/java-install \
    && mkdir -p /tmp/gradle-install \
    && mkdir -p /tmp/cmdline-tools-install

# 设置 Android SDK 环境变量
ENV ANDROID_HOME=/opt/android-sdk \
    PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

# 下载并安装 Android Command Line Tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip \
    -O /tmp/cmdline-tools.zip \
    && unzip /tmp/cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools \
    && mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip \
    # 接受所有许可证
    && yes | sdkmanager --licenses > /dev/null 2>&1 \
    # 安装基本组件
    && sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" > /dev/null 2>&1

# 设置工作目录
WORKDIR /app

# 从构建阶段复制依赖
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 复制应用代码
COPY . .

# 复制 Docker 环境配置
COPY .env.docker .env

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3000/health')" || exit 1

# 启动命令
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3000"]
