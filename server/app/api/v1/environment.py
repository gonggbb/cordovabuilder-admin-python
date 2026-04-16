import json
import os
import traceback
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from loguru import logger
from app.services.env_script_executor_service import ScriptExecutor

# 创建路由器
router = APIRouter()

# 创建服务实例
script_executor = ScriptExecutor()


class SetupEnvironmentRequest(BaseModel):
    """
    设置环境请求模型
    """
    profile: str = "ca12"  # 预设配置: ca11|ca12|ca14|ca15
    node_version: Optional[str] = None  # Node.js 版本
    java_major: Optional[str] = None  # Java 主版本号
    java_version: Optional[str] = None  # Java 完整版本
    gradle_version: Optional[str] = None  # Gradle 版本
    build_tools_version: Optional[str] = None  # Android Build Tools 版本
    platform_api: Optional[str] = None  # Android Platform API 版本 "36" (纯 API 级别数字)
    cmdline_version: Optional[str] = None  # Command Line Tools 版本


@router.post("/setup")
async def setup_environment(request: SetupEnvironmentRequest):
    """
    设置 Cordova 构建环境
    
    调用 setup_cordova_env.sh 脚本安装和配置所有必要的构建工具。
    支持预设配置和自定义参数覆盖。
    
    Args:
        request: 环境设置请求
        
    Returns:
        dict: 执行结果，包含成功状态、输出信息等
    """
    try:
        # 打印请求对象
        print(f"=== Request Object ===")
        print(f"Type: {type(request)}")
        print(f"Dict: {request.model_dump()}")
        logger.info(f"Loaded presets: {request}")
        print(f"=====================")
        # 如果用户没有指定具体版本，则从预设配置中自动补全
        if not any([request.node_version, request.java_major, request.gradle_version]):
            config_path = os.path.join(os.path.dirname(__file__), '..', '..', 'configs', 'env_presets.json')
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    presets = json.load(f)
                logger.info(f"Loaded presets: {presets}")
                if request.profile in presets:
                    profile_config = presets[request.profile]
                    profile_details = profile_config.get('profile', {})
                    
                    # 仅当用户未提供时才使用预设值
                    if not request.node_version:
                        request.node_version = profile_details.get('node')
                    if not request.java_major:
                        request.java_major = str(profile_details.get('java'))
                    if not request.gradle_version:
                        request.gradle_version = profile_details.get('gradle')
                    if not request.build_tools_version:
                        # 处理 buildTools 中的 ^ 符号
                        bt = profile_config.get('buildTools', '')
                        request.build_tools_version = bt.lstrip('^')
                    if not request.platform_api:
                        request.platform_api = str(profile_details.get('sdk'))
            except Exception as e:
                logger.error(f"Could not load presets for auto-fill: {e}")
                logger.error(f"Exception traceback:\n{traceback.format_exc()}")

        result = await script_executor.setup_cordova_environment(
            profile=request.profile,
            node_version=request.node_version,
            java_major=request.java_major,
            java_version=request.java_version,
            gradle_version=request.gradle_version,
            build_tools_version=request.build_tools_version,
            platform_api=request.platform_api,
            cmdline_version=request.cmdline_version
        )
        
        if not result['success']:
            raise HTTPException(
                status_code=500,
                detail={
                    'message': 'Environment setup failed',
                    'error': result['stderr'],
                    'output': result['stdout']
                }
            )
        
        return {
            'success': True,
            'message': 'Environment setup completed successfully',
            'output': result['stdout']
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error in setup_environment: {e}")
        logger.error(f"Exception traceback:\n{traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))



@router.get("/cordova-presets")
def get_presets():
    """
    获取可用的预设配置列表
    
    Returns:
        dict: 预设配置信息
    """
    # 从共享的 JSON 配置文件中读取
    config_path = os.path.join(os.path.dirname(__file__), '..', '..', 'configs', 'env_presets.json')
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            presets = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        raise HTTPException(status_code=500, detail=f"Failed to load environment presets: {str(e)}")
    
    return {
        "presets": presets,
        "default": "",
        "count": len(presets)
    }


