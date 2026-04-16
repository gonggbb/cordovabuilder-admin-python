#!/bin/bash

$1/bin/sdkmanager --version
$1/bin/sdkmanager --version 2>&1 | grep "class file"

jar_file=/lib/sdklib/libsdkmanager_lib.jar

echo "-> $jar_file"
# 使用 javap 命令解析 JAR 文件内指定的 class
output=$(javap -verbose -classpath "$1${jar_file}" com.android.sdklib.tool.sdkmanager.SdkManagerCliSettings 2>&1)

#echo "$output"
# 查找主要版本号
major_version=$(echo "$output" | grep  'major version')
# 打印主要版本号
echo "--> $major_version"

##---
jar_file=/lib/common/tools.common.jar

echo
echo "-> $jar_file"
# 使用 javap 命令解析 JAR 文件内指定的 class
output=$(javap -verbose -classpath "$1${jar_file}" com.android.prefs.AndroidLocationsProvider 2>&1)
# 查找主要版本号
major_version=$(echo "$output" | grep  'major version')
# # 打印主要版本号
echo "--> $major_version"