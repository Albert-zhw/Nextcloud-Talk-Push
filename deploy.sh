#!/bin/bash
# Nextcloud Talk Push 部署脚本

set -e

# TODO: 替换为您的 Nextcloud 容器名
CONTAINER_NAME="your-nextcloud-container"
APP_PATH="/config/www/nextcloud/apps/talkpush"

echo "=== Nextcloud Talk Push 部署脚本 ==="
echo ""

# 检查容器是否运行
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "❌ 错误：Nextcloud 容器未运行"
    exit 1
fi

echo "✓ Nextcloud 容器运行正常"

# 创建目录结构
echo ""
echo "正在创建应用目录..."
docker exec $CONTAINER_NAME mkdir -p $APP_PATH/appinfo
docker exec $CONTAINER_NAME mkdir -p $APP_PATH/lib/AppInfo
docker exec $CONTAINER_NAME mkdir -p $APP_PATH/lib/Listener

# 复制文件
echo "正在复制应用文件..."
docker cp ./info.xml $CONTAINER_NAME:$APP_PATH/appinfo/info.xml
docker cp ./Application.php $CONTAINER_NAME:$APP_PATH/lib/AppInfo/Application.php
docker cp ./ChatMessageListener.php $CONTAINER_NAME:$APP_PATH/lib/Listener/ChatMessageListener.php

# 设置权限
echo "正在设置文件权限..."
docker exec $CONTAINER_NAME chown -R abc:users $APP_PATH

# 启用应用
echo "正在启用应用..."
docker exec $CONTAINER_NAME php /app/www/public/occ app:enable talkpush

echo ""
echo "✅ 部署完成！"
echo ""
echo "查看应用状态:"
echo "  docker exec $CONTAINER_NAME php /app/www/public/occ app:info talkpush"
echo ""
echo "查看推送日志:"
echo "  docker exec $CONTAINER_NAME tail -f /tmp/talkpush.log"
echo ""
