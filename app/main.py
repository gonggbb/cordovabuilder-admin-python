from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings
from loguru import logger
from typing import List
import sys
from pathlib import Path

# 导入 API 路由
from app.api.v1 import environment


# 配置日志级别（从系统环境变量或默认值）
LOGURU_LEVEL = "DEBUG"  # 可选: DEBUG, INFO, WARNING, ERROR


class Settings(BaseSettings):
    """
    应用配置类
    
    配置加载优先级:
    1. 系统环境变量（最高优先级）
    2. .env 文件
    3. Settings 类中的默认值（最低优先级）
    """
    # ============================================
    # 服务器配置
    # ============================================
    PORT: int = 3000  # 服务端口
    CORS_ORIGINS: List[str] = ["*"]  # CORS 允许的源
    
    # ============================================
    # 日志配置
    # ============================================
    LOGURU_LEVEL: str = "DEBUG"  # 日志级别: DEBUG, INFO, WARNING, ERROR
    
    # ============================================
    # 配置选项
    # ============================================
    class Config:
        env_file = ".env"  # 从 .env 文件读取配置
        env_file_encoding = "utf-8"  # .env 文件编码
        case_sensitive = True  # 区分大小写
        # extra = "ignore"  # 忽略额外的环境变量，不报错


# 创建配置实例
settings = Settings()


# 配置 Loguru 日志系统（从 settings 中读取 LOGURU_LEVEL）
logger.remove()  # 移除默认的 handler
logger.add(
    sys.stderr,
    level=settings.LOGURU_LEVEL,  # 从 .env 文件或系统环境变量读取
    format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>"
)

# 可选：同时输出到文件
project_root = Path(__file__).parent.parent
logs_dir = project_root / "logs"
logs_dir.mkdir(exist_ok=True)

logger.add(
    logs_dir / "app_{time:YYYY-MM-DD}.log",
    rotation="00:00",  # 每天午夜轮换
    retention="7 days",  # 保留 7 天
    level=settings.LOGURU_LEVEL,
    encoding="utf-8"
)

# 记录配置信息
logger.info("=" * 60)
logger.info("CordovaBuilder Admin API 配置加载完成")
logger.info(f"服务端口: {settings.PORT}")
logger.info(f"CORS 源: {settings.CORS_ORIGINS}")
logger.info(f"日志级别: {settings.LOGURU_LEVEL}")
logger.info("=" * 60)


# 创建 FastAPI 应用实例
app = FastAPI(
    title="CordovaBuilder Admin API",
    description="CordovaBuilder 项目管理后端服务器 API 文档 (Python版)",
    version="1.0.0",
    docs_url="/docs",  # Swagger UI 文档路径
    redoc_url="/redoc",  # ReDoc 文档路径
    openapi_url="/openapi.json"  # OpenAPI JSON 路径
)

# 配置 CORS 中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],  # 允许所有 HTTP 方法
    allow_headers=["*"],  # 允许所有请求头
)

# 注册路由
app.include_router(environment.router, prefix="/api/environment", tags=["环境管理"])


@app.get("/")
def read_root():
    """
    根路径，返回欢迎信息和系统配置
    
    Returns:
        dict: 欢迎消息和系统信息
    """
    return {
        "message": "CordovaBuilder Admin API is running",
        "version": "1.0.0",
    }


@app.get("/health")
def health_check():
    """
    健康检查接口
    
    Returns:
        dict: 服务健康状态
    """
    return {
        "status": "healthy",
        "timestamp": "2026-04-09T15:50:00Z"
    }


@app.on_event("startup")
async def startup_event():
    """
    应用启动事件
    
    在应用启动时执行，记录启动日志和环境变量信息
    """
    logger.info("=" * 60)
    logger.info("CordovaBuilder Admin API 启动中...")
    logger.info("=" * 60)
    logger.info(f"服务端口: {settings.PORT}")
    logger.info("=" * 60)
    logger.success("CordovaBuilder Admin API 启动成功！")
    logger.info(f"API 文档地址: http://localhost:{settings.PORT}/docs")
    logger.info(f"ReDoc 文档地址: http://localhost:{settings.PORT}/redoc")


if __name__ == "__main__":
    import uvicorn
    # 启动 Uvicorn 服务器
    uvicorn.run(app, host="0.0.0.0", port=settings.PORT)
