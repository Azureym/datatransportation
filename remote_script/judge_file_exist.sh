#!/bin/bash

# 删除之前运行产生的遗留文件
[ -f "/tmp/apt_log.sql.dat" ] && sudo rm /tmp/apt_log.sql.dat
[ -f "/tmp/apt.sql.dat" ] && sudo rm /tmp/apt.sql.dat
[ -f "/tmp/biz_settings.sql.dat" ] && sudo rm /tmp/biz_settings.sql.dat
[ -f "/tmp/room_status.sql.dat" ] && sudo rm /tmp/room_status.sql.dat
[ -f "/tmp/apt_maxid.sql.dat" ] && sudo rm /tmp/apt_maxid.sql.dat
[ -f "/tmp/log_maxid.sql.dat" ] && sudo rm /tmp/log_maxid.sql.dat
