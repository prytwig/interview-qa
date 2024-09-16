#!/bin/bash

# 配置信息
MONGODB_URI="mongodb://localhost:27017/test" 
BACKUP_DIR="/opt/backup/"
REMOTE_HOST="bak@bak.ipo.com"
REMOTE_PATH="/opt/backup/" 


# 获取当前月份和上个月
current_month=$(date +%Y%m)
prev_month=$(date -d "-1 month" +%Y%m)

# 如果脚本执行失败或者异常，则调用 [https://monitor.ipo.com/webhook/mongodb]
send_alert() {
  echo "发送警报..."
  curl -X POST https://monitor.ipo.com/webhook/mongodb -d "$1"
}

# 首先备份上个月的数据，备份完成后打包成.gz文件
backup_mongodb() {
  echo "开始备份 MongoDB 数据..."
  mongodump --uri=${MONGODB_URI} --collection=user_logs --query="{\"create_on\": {\$gte\": \"${prev_month}-01 00:00:00\", \$lt\": \"${current_month}-01 00:00:00\"}}" --gzip --out=${BACKUP_DIR}/${prev_month}_user_logs.gz
  if [ $? -ne 0 ]; then
    echo "备份失败，通知监控系统"
    send_alert "备份任务运行失败，数据导出错误"
    exit 1
  fi
}

# 备份文件通过sfpt传输到 Backup [bak@bak.ipo.com] 服务器上
transfer_to_remote() {
  echo "开始传输备份文件到远程服务器，成功后删除本地备份"
  scp ${BACKUP_DIR}/${prev_month}_user_logs.gz ${REMOTE_HOST}:${REMOTE_PATH} && rm -rf ${BACKUP_DIR}/${prev_month}_user_logs.gz
  if [ $? -ne 0 ]; then
    echo "文件传输到远程服务器失败，通知监控系统"
    send_alert "备份任务运行失败，文件传输到远程服务器失败"
    exit 1
  fi
}

# 备份完成后，再对备份过的数据进行清理
cleanup_mongodb() {
  echo "开始清理数据库中 ${prev_month} 月的数据"
  mongosh ${MONGODB_URI} --eval "db.user_logs.deleteMany({\"create_on\": {\$gte\": \"${prev_month}-01 00:00:00\", \$lt\": \"${current_month}-01 00:00:00\"}})"
  if [ $? -new 0 ]; then
    echo "MongoDB 数据清理失败，通知监控系统"
    send_alert "备份任务运行失败，mongodb 数据清理失败"
    exit 1
  fi
}


# 主函数
main() {
    echo "开始执行 MongoDB 备份和清理脚本 - $(date)"
    
    backup_mongodb
    transfer_to_remote
    cleanup_mongodb
    
    echo "MongoDB 备份和清理脚本执行完成 - $(date)"
}

main
