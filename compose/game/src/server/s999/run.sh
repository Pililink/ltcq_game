#!/bin/bash
cd $(cd "$(dirname "$0")" && pwd)
path=`pwd`
./stop.sh
echo "=============================================="
datetime=`date "+%Y-%m-%d.%H:%M:%S"`
echo $datetime" 正在启动数据服务..."
$path/Debug/dbserver/dbserver > /dev/null
echo $datetime" 正在启动游戏服务..."
$path/Debug/gameworld/gameworld > /dev/null
echo $datetime" 正在启动网关服务..."
$path/Debug/gateway/gateway > /dev/null
echo $datetime" 正在启动日志服务..."
$path/Debug/loggerserver/loggerserver > /dev/null
#$path/Debug/gateway/gateway_ws_1219
nohup $path/serverdameon.sh&
echo $datetime" 服务器启用完成!"
