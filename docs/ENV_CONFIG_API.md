# 环境配置管理 API 文档

## 概述

环境配置管理模块用于管理 Cordova 构建环境的配置模板。每个配置定义了一套完整的构建环境,包括 Cordova、Android SDK、Gradle、Java 和 Node.js 的版本信息。

## 数据模型

### EnvProfile (环境配置文件)

```json
{
  "sdk": "32.0.0",        // Android SDK 版本
  "gradle": "7.4.2",      // Gradle 版本
  "java": "11",           // Java JDK 版本
  "node": "18.20.8"       // Node.js 版本
}
```

### EnvConfig (环境配置)

```json
{
  "name": "cordova-12-ca11",                    // 环境配置名称(唯一标识)
  "description": "Cordova 12 + cordova-android 11.0.x",  // 环境描述
  "cordovaVersion": "12.x",                     // Cordova 版本
  "cordovaAndroid": "11.0.x",                   // cordova-android 版本
  "buildTools": "^32.0.0",                      // Android Build Tools 版本
  "profile": {                                  // 环境配置文件
    "sdk": "32.0.0",
    "gradle": "7.4.2",
    "java": "11",
    "node": "18.20.8"
  }
}
```

## API 接口

### 1. 获取所有环境配置列表

**接口:** `GET /api/env-config/list`

**响应:**
```json
{
  "total": 2,
  "items": [
    {
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
    }
  ]
}
```

### 2. 获取单个环境配置

**接口:** `GET /api/env-config/{name}`

**路径参数:**
- `name`: 环境配置名称

**响应:** 返回单个 EnvConfig 对象

**错误:**
- `404`: 配置不存在

### 3. 创建环境配置

**接口:** `POST /api/env-config/`

**请求体:** EnvConfig 对象

**响应:** 返回创建的 EnvConfig 对象

**状态码:**
- `201`: 创建成功
- `409`: 配置名称已存在
- `500`: 服务器错误

**示例:**
```bash
curl -X POST http://localhost:3000/api/env-config/ \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

### 4. 更新环境配置

**接口:** `PUT /api/env-config/{name}`

**路径参数:**
- `name`: 要更新的环境配置名称

**请求体:** EnvConfig 对象

**响应:** 返回更新后的 EnvConfig 对象

**状态码:**
- `200`: 更新成功
- `404`: 配置不存在
- `409`: 新名称与其他配置冲突
- `500`: 服务器错误

**示例:**
```bash
curl -X PUT http://localhost:3000/api/env-config/cordova-12-ca11 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "cordova-12-ca11-updated",
    "description": "Updated description",
    "cordovaVersion": "12.x",
    "cordovaAndroid": "11.0.x",
    "buildTools": "^32.0.0",
    "profile": {
      "sdk": "32.0.0",
      "gradle": "7.4.2",
      "java": "11",
      "node": "18.20.8"
    }
  }'
```

### 5. 删除环境配置

**接口:** `DELETE /api/env-config/{name}`

**路径参数:**
- `name`: 要删除的环境配置名称

**响应:**
```json
{
  "success": true,
  "message": "环境配置 'cordova-12-ca11' 已成功删除"
}
```

**状态码:**
- `200`: 删除成功
- `404`: 配置不存在
- `500`: 服务器错误

## 数据存储

环境配置数据存储在 JSON 文件中:
- **默认路径:** `/workspace/env-configs.json` (Docker 环境)
- **本地路径:** 由 `WORKSPACE_DIR` 环境变量控制

文件格式:
```json
[
  {
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
  }
]
```

## 测试

运行测试脚本:

```bash
# 确保服务正在运行
poetry run uvicorn app.main:app --reload --port 3000

# 运行测试
poetry run python tests/test_env_config.py
```

## 使用场景

### 场景 1: 预定义构建环境

为不同的 Cordova 项目预定义构建环境配置:

```python
# 创建多个环境配置
configs = [
    {
        "name": "cordova-11-ca10",
        "description": "Cordova 11 + cordova-android 10.x",
        "cordovaVersion": "11.x",
        "cordovaAndroid": "10.x",
        "buildTools": "^30.0.0",
        "profile": {
            "sdk": "30.0.0",
            "gradle": "7.0.0",
            "java": "11",
            "node": "16.x"
        }
    },
    {
        "name": "cordova-12-ca11",
        "description": "Cordova 12 + cordova-android 11.x",
        "cordovaVersion": "12.x",
        "cordovaAndroid": "11.x",
        "buildTools": "^32.0.0",
        "profile": {
            "sdk": "32.0.0",
            "gradle": "7.4.2",
            "java": "11",
            "node": "18.x"
        }
    }
]
```

### 场景 2: CI/CD 集成

在 CI/CD 流程中根据项目名称自动选择对应的环境配置:

```python
# 获取项目对应的环境配置
config_name = get_project_env_config(project_name)
response = requests.get(f"http://localhost:3000/api/env-config/{config_name}")
env_config = response.json()

# 根据配置安装相应的工具
install_node(env_config['profile']['node'])
install_java(env_config['profile']['java'])
install_gradle(env_config['profile']['gradle'])
install_android_sdk(env_config['profile']['sdk'])
```

### 场景 3: 环境迁移

当需要升级某个项目的构建环境时:

```python
# 1. 获取当前配置
response = requests.get("http://localhost:3000/api/env-config/cordova-12-ca11")
current_config = response.json()

# 2. 修改配置
current_config['profile']['gradle'] = '8.0.0'
current_config['profile']['node'] = '20.x'

# 3. 更新配置
requests.put(
    "http://localhost:3000/api/env-config/cordova-12-ca11",
    json=current_config
)
```

## 注意事项

1. **名称唯一性**: 环境配置名称必须唯一,不能重复
2. **持久化存储**: 配置数据保存在 JSON 文件中,重启服务后数据不会丢失
3. **Docker 部署**: 在 Docker 环境中,确保挂载了 `/workspace` 目录以持久化配置数据
4. **版本格式**: 版本号格式应遵循各工具的官方规范 (如 semver)
