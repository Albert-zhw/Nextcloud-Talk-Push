#!/bin/bash

# Nextcloud Talk Push 控制脚本
# 用于启动、停止和查看推送服务状态

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# TODO: 替换为您的 Nextcloud 容器名
NEXTCLOUD_CONTAINER="your-nextcloud-container"

# 打印帮助信息
print_help() {
    echo "用法：$0 {start|stop|restart|status|logs}"
    echo ""
    echo "命令说明:"
    echo "  start   - 启动推送服务（启用 talkpush 应用）"
    echo "  stop    - 停止推送服务（禁用 talkpush 应用）"
    echo "  restart - 重启推送服务"
    echo "  status  - 查看服务状态"
    echo "  logs    - 查看实时日志"
    echo ""
    echo "示例:"
    echo "  $0 start    # 启动推送"
    echo "  $0 stop     # 停止推送"
    echo "  $0 logs     # 查看实时日志"
}

# 检查容器是否运行
check_container() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${NEXTCLOUD_CONTAINER}$"; then
        echo -e "${RED}错误：Nextcloud 容器 '${NEXTCLOUD_CONTAINER}' 未运行${NC}"
        exit 1
    fi
}

# 启动服务
start_service() {
    echo -e "${YELLOW}正在启动 Nextcloud Talk Push 服务...${NC}"
    
    check_container
    
    # 启用应用
    docker exec "${NEXTCLOUD_CONTAINER}" php /app/www/public/occ app:enable talkpush
    
    echo -e "${GREEN}✅ 推送服务已启动${NC}"
    echo ""
    echo "查看日志：$0 logs"
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}正在停止 Nextcloud Talk Push 服务...${NC}"
    
    check_container
    
    # 禁用应用
    docker exec "${NEXTCLOUD_CONTAINER}" php /app/www/public/occ app:disable talkpush
    
    echo -e "${GREEN}✅ 推送服务已停止${NC}"
    echo ""
    echo "注意：禁用应用后，Talk 消息将不再推送到回逍"
}

# 重启服务
restart_service() {
    echo -e "${YELLOW}正在重启 Nextcloud Talk Push 服务...${NC}"
    
    check_container
    
    # 禁用应用
    docker exec "${NEXTCLOUD_CONTAINER}" php /app/www/public/occ app:disable talkpush
    sleep 2
    
    # 启用应用
    docker exec "${NEXTCLOUD_CONTAINER}" php /app/www/public/occ app:enable talkpush
    
    echo -e "${GREEN}✅ 推送服务已重启${NC}"
}

# 查看状态
check_status() {
    echo -e "${YELLOW}Nextcloud Talk Push 服务状态：${NC}"
    echo ""
    
    check_container
    
    # 检查应用是否启用
    if docker exec "${NEXTCLOUD_CONTAINER}" php /app/www/public/occ app:list | grep -q "talkpush"; then
        echo -e "${GREEN}● talkpush 应用已启用${NC}"
        
        # 查看日志文件是否存在
        if docker exec "${NEXTCLOUD_CONTAINER}" test -f /tmp/talkpush.log; then
            echo -e "${GREEN}● 日志文件正常${NC}"
            
            # 显示最近 5 条推送记录
            echo ""
            echo "最近推送记录:"
            docker exec "${NEXTCLOUD_CONTAINER}" tail -n 5 /tmp/talkpush.log | sed 's/^/  /'
        else
            echo -e "${YELLOW}● 日志文件不存在（可能是首次运行）${NC}"
        fi
    else
        echo -e "${RED}● talkpush 应用未启用${NC}"
    fi
    
    echo ""
    echo "容器状态:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "${NEXTCLOUD_CONTAINER}" || true
}

# 查看实时日志
view_logs() {
    echo -e "${YELLOW}实时查看推送日志（按 Ctrl+C 退出）...${NC}"
    echo ""
    
    check_container
    
    if ! docker exec "${NEXTCLOUD_CONTAINER}" test -f /tmp/talkpush.log; then
        echo -e "${RED}日志文件不存在${NC}"
        exit 1
    fi
    
    docker exec -it "${NEXTCLOUD_CONTAINER}" tail -f /tmp/talkpush.log
}

# 主程序
case "${1:-}" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        check_status
        ;;
    logs)
        view_logs
        ;;
    help|--help|-h|"")
        print_help
        ;;
    *)
        echo -e "${RED}错误：未知命令 '${1}'${NC}"
        print_help
        exit 1
        ;;
esac
