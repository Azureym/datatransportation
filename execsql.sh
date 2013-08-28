#!/bin/bash

# command argument
USER=$1
HOST=$2

DB_USER=$3
DB_PASSWD=$4
DB_NAME=$5

DB_USER_REMOTE=$6
DB_PASSWD_REMOTE=$7
DB_NAME_REMOTE=$8

# 删除本地/tmp/目录下的遗留文件
./remote_script/judge_file_exist.sh

# 本地执行sql脚本导出数据,导出数据将会放置在当前机器/tmp/目录下
mysql -u${DB_USER} -p${DB_PASSWD} -D${DB_NAME} -e "source local_sql/createTmpTable.sql; source local_sql/dataTransport.sql; source local_sql/exportSqlScript.sql;"
# 上传远程执行的shell脚本至目标机器的/tmp/目录下
scp remote_script/* ${USER}@${HOST}:/tmp/
# 首先删除有可能在远端机器/tmp/下产生的重复文件
ssh ${USER}@${HOST} "/tmp/judge_file_exist.sh"

# 将生成的导入数据上传到远端机器
scp /tmp/*.sql.dat ${USER}@${HOST}:/tmp/
ssh ${USER}@${HOST} "mysql -h${HOST} -u${DB_USER_REMOTE} -p${DB_PASSWD_REMOTE} -D${DB_NAME_REMOTE} -e \"load data infile '/tmp/apt_log.sql.dat' into table hotel_apt_logs character set utf8; load data infile '/tmp/apt.sql.dat' into table hotel_apt character set utf8; load data infile '/tmp/biz_settings.sql.dat' into table hotel_apt_biz_settings character set utf8; load data infile '/tmp/room_status.sql.dat' into table hotel_apt_room_status character set utf8\""
# 修改远端数据库`hotel_apt`与`hotel_apt_logs`表中auto_increment 值
ssh ${USER}@${HOST} "/tmp/alter_table_increment.sh ${DB_USER_REMOTE} ${DB_PASSWD_REMOTE} ${DB_NAME_REMOTE}"

