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
    presets = {
        "ca11": {
            "name": "cordova-12-ca11",
            "description": "Cordova 12 + cordova-android 11.0.x",
            "cordovaVersion": "12.x",
            "cordovaAndroid": "11.0.x",
            "buildTools": "^32.0.0",
            "profile": {
                "sdk": "32.0.0",
                "gradle": "7.4.2",
                "java": "11",
                "node": "18.20.8"
            }
        },
        "ca12": {
            "name": "cordova-12-ca12",
            "description": "Cordova 12 + cordova-android 12.0.x",
            "cordovaVersion": "12.x",
            "cordovaAndroid": "12.0.x",
            "buildTools": "^33.0.0",
            "profile": {
                "sdk": "33.0.0",
                "gradle": "7.6",
                "java": "17",
                "node": "18.20.8"
            }
        },
        "ca14": {
            "name": "cordova-13-ca14",
            "description": "Cordova 13 + cordova-android 14.0.x",
            "cordovaVersion": "13.x",
            "cordovaAndroid": "14.0.x",
            "buildTools": "^35.0.0",
            "profile": {
                "sdk": "35.0.0",
                "gradle": "8.13",
                "java": "17",
                "node": "20.19.5"
            }
        },
        "ca15": {
            "name": "cordova-13-ca15",
            "description": "Cordova 13 + cordova-android 15.0.x",
            "cordovaVersion": "13.x",
            "cordovaAndroid": "15.0.x",
            "buildTools": "^36.0.0",
            "profile": {
                "sdk": "36.0.0",
                "gradle": "8.14.2",
                "java": "17",
                "node": "20.19.5"
            }
        }
    }
    
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
