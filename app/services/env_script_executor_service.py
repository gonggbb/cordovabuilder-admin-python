import os
import asyncio
import shutil
from pathlib import Path
from typing import Optional, Dict, Any
from loguru import logger


class ScriptExecutor:
    """
    脚本执行器服务
    
    提供统一的 Bash 脚本执行功能，支持异步调用和结果返回
    """
    
    def __init__(self):
        """
        初始化脚本执行器
        
        定位 scripts 目录路径
        """
        project_root = Path(__file__).parent.parent.parent
        self.scripts_dir = project_root / "scripts"
        
        logger.info(f"Scripts directory: {self.scripts_dir}")
    
    async def execute_script(
        self,
        script_name: str,
        args: list[str] = None,
        timeout: int = 3600
    ) -> Dict[str, Any]:
        """
        执行 Bash 脚本
        
        Args:
            script_name: 脚本文件名 (如 setup_cordova_env.sh)
            args: 命令行参数列表
            timeout: 超时时间（秒），默认 1 小时
            
        Returns:
            dict: 包含执行结果的字典
                - success: bool - 是否成功
                - stdout: str - 标准输出
                - stderr: str - 错误输出
                - returncode: int - 返回码
                
        Raises:
            FileNotFoundError: 脚本文件不存在
            RuntimeError: bash 命令不可用
        """
        script_path = self.scripts_dir / script_name
        
        # 检查脚本是否存在
        if not script_path.exists():
            raise FileNotFoundError(f"Script not found: {script_path}")
        
        # 检查 bash 是否可用
        bash_path = shutil.which("bash")
        if not bash_path:
            raise RuntimeError("bash not found. Cannot execute shell scripts.")
        
        # 构建命令
        cmd = [bash_path, str(script_path)]
        if args:
            cmd.extend(args)
        
        logger.info(f"Executing script: {' '.join(cmd)}")
        
        try:
            # 异步执行脚本
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            
            # 等待执行完成（带超时）
            stdout, stderr = await asyncio.wait_for(
                process.communicate(),
                timeout=timeout
            )
            
            # 解码输出
            stdout_text = stdout.decode('utf-8', errors='ignore').strip()
            stderr_text = stderr.decode('utf-8', errors='ignore').strip()
            
            result = {
                'success': process.returncode == 0,
                'stdout': stdout_text,
                'stderr': stderr_text,
                'returncode': process.returncode
            }
            
            if process.returncode == 0:
                logger.success(f"Script executed successfully: {script_name}")
            else:
                logger.error(f"Script failed with code {process.returncode}: {script_name}")
                logger.error(f"stderr: {stderr_text}")
            
            return result
            
        except asyncio.TimeoutError:
            logger.error(f"Script execution timed out ({timeout}s): {script_name}")
            # 尝试终止进程
            try:
                process.kill()
            except:
                pass
            return {
                'success': False,
                'stdout': '',
                'stderr': f'Execution timed out after {timeout} seconds',
                'returncode': -1
            }
        except Exception as e:
            logger.error(f"Script execution error: {str(e)}")
            raise
    
    async def setup_cordova_environment(
        self,
        profile: str = "ca12",
        node_version: Optional[str] = None,
        java_major: Optional[str] = None,
        java_version: Optional[str] = None,
        gradle_version: Optional[str] = None,
        build_tools_version: Optional[str] = None,
        platform_api: Optional[str] = None,
        cmdline_version: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        设置 Cordova 构建环境
        
        Args:
            profile: 预设配置 (ca11|ca12|ca14|ca15)
            node_version: Node.js 版本
            java_major: Java 主版本号
            java_version: Java 完整版本
            gradle_version: Gradle 版本
            build_tools_version: Android Build Tools 版本
            platform_api: Android Platform API 版本
            cmdline_version: Command Line Tools 版本
            
        Returns:
            dict: 执行结果
        """
        args = ["--profile", profile]
        
        if node_version:
            args.extend(["--node", node_version])
        if java_major:
            args.extend(["--java-major", java_major])
        if java_version:
            args.extend(["--java", java_version])
        if gradle_version:
            args.extend(["--gradle", gradle_version])
        if build_tools_version:
            args.extend(["--build-tools", build_tools_version])
        if platform_api:
            args.extend(["--platform", platform_api])
        if cmdline_version:
            args.extend(["--cmdline", cmdline_version])
        
        return await self.execute_script("setup_cordova_env.sh", args)
    

        """
        切换环境变量（通过更新符号链接）
        
        Args:
            node_version: Node.js 版本
            java_version: Java 版本
            gradle_version: Gradle 版本
            
        Returns:
            dict: 执行结果
        """
        args = []
        
        # 注意：需要扩展脚本以支持仅切换版本而不重新安装
        # 这里先返回提示信息
        return {
            'success': False,
            'stdout': '',
            'stderr': 'Environment switching not yet implemented. Please use full setup.',
            'returncode': -1
        }