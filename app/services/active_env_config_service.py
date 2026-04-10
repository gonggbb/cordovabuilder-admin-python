"""
环境激活配置管理服务

负责管理当前激活的环境配置，将配置保存到本地文件
"""
import json
from pathlib import Path
from typing import Optional, Dict, Any
from loguru import logger


class ActiveEnvConfigService:
    """
    激活的环境配置服务
    
    功能：
    - 保存当前激活的配置到本地文件
    - 读取当前激活的配置
    - 清除激活的配置
    """
    
    def __init__(self):
        """
        初始化服务
        
        配置文件保存在项目根目录的 .active-env.json
        """
        # 获取项目根目录
        self.project_root = Path(__file__).parent.parent.parent
        self.config_file = self.project_root / ".active-env.json"
        
        logger.info(f"激活配置工作目录: {self.project_root}")
        logger.info(f"激活配置文件路径: {self.config_file}")
    
    def save_active_config(self, profile: str, config_data: Dict[str, Any]) -> bool:
        """
        保存当前激活的配置
        
        Args:
            profile: 配置名称 (如 "ca11", "ca12")
            config_data: 配置数据
            
        Returns:
            bool: 是否保存成功
        """
        try:
            active_config = {
                "profile": profile,
                "config": config_data,
                "timestamp": self._get_timestamp()
            }
            
            # 确保目录存在
            self.config_file.parent.mkdir(parents=True, exist_ok=True)
            
            # 写入配置文件
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(active_config, f, indent=2, ensure_ascii=False)
            
            logger.success(f"激活配置已保存: {profile}")
            return True
            
        except Exception as e:
            logger.error(f"保存激活配置失败: {str(e)}")
            return False
    
    def get_active_config(self) -> Optional[Dict[str, Any]]:
        """
        获取当前激活的配置
        
        Returns:
            dict or None: 激活的配置信息，如果不存在则返回 None
        """
        try:
            if not self.config_file.exists():
                logger.info("未找到激活的配置文件")
                return None
            
            with open(self.config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            logger.info(f"当前激活配置: {config.get('profile', 'unknown')}")
            return config
            
        except Exception as e:
            logger.error(f"读取激活配置失败: {str(e)}")
            return None
    
    def clear_active_config(self) -> bool:
        """
        清除当前激活的配置
        
        Returns:
            bool: 是否清除成功
        """
        try:
            if self.config_file.exists():
                self.config_file.unlink()
                logger.info("激活配置已清除")
            else:
                logger.info("没有激活的配置需要清除")
            
            return True
            
        except Exception as e:
            logger.error(f"清除激活配置失败: {str(e)}")
            return False
    
    def _get_timestamp(self) -> str:
        """
        获取当前时间戳
        
        Returns:
            str: ISO 格式的时间戳
        """
        from datetime import datetime
        return datetime.now().isoformat()


# 创建单例实例
active_env_config_service = ActiveEnvConfigService()
