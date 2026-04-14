import json
import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from app.services.env_script_executor_service import ScriptExecutor
from app.services.active_env_config_service import active_env_config_service

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
    platform_api: Optional[str] = None  # Android Platform API 版本
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
        # 如果用户没有指定具体版本，则从预设配置中自动补全
        if not any([request.node_version, request.java_major, request.gradle_version]):
            config_path = os.path.join(os.path.dirname(__file__), '..', '..', 'configs', 'env_presets.json')
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    presets = json.load(f)
                
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
                logger.warning(f"Could not load presets for auto-fill: {e}")

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
        "default": "ca12",
        "count": len(presets)
    }


class ActivateConfigRequest(BaseModel):
    """
    激活配置请求模型
    """
    profile: str  # 配置名称 (如 "ca11", "ca12")


@router.post("/activate")
async def activate_config(request: ActivateConfigRequest):
    """
    激活指定的环境配置
    
    将配置保存到本地文件 (.active-env.json)，记录当前使用的配置。
    
    Args:
        request: 激活配置请求
        
    Returns:
        dict: 激活结果
    """
    try:
        # 验证配置是否存在
        presets_response = get_presets()
        if request.profile not in presets_response["presets"]:
            raise HTTPException(
                status_code=404,
                detail=f"配置 '{request.profile}' 不存在。可用配置: {list(presets_response['presets'].keys())}"
            )
        
        # 获取配置详情
        preset_config = presets_response["presets"][request.profile]
        
        # 保存激活的配置
        success = active_env_config_service.save_active_config(
            profile=request.profile,
            config_data=preset_config
        )
        
        if not success:
            raise HTTPException(
                status_code=500,
                detail="保存激活配置失败"
            )
        
        return {
            "success": True,
            "message": f"配置 '{request.profile}' 已激活",
            "profile": request.profile,
            "config": preset_config
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/active")
def get_active_config():
    """
    获取当前激活的配置
    
    Returns:
        dict: 当前激活的配置信息，如果没有激活则返回 null
    """
    try:
        active_config = active_env_config_service.get_active_config()
        
        if active_config is None:
            return {
                "success": True,
                "active": False,
                "profile": None,
                "config": None
            }
        
        return {
            "success": True,
            "active": True,
            "profile": active_config.get("profile"),
            "config": active_config.get("config"),
            "activated_at": active_config.get("timestamp")
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/active")
def deactivate_config():
    """
    清除当前激活的配置
    
    Returns:
        dict: 操作结果
    """
    try:
        success = active_env_config_service.clear_active_config()
        
        if not success:
            raise HTTPException(
                status_code=500,
                detail="清除激活配置失败"
            )
        
        return {
            "success": True,
            "message": "激活配置已清除"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
