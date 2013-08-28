#!/bin/bash

DB_USER=$1
DB_PASSWD=$2
DB_NAME=$3
:<<BLOCK
pwd
if [ -f "/tmp/apt_maxid.sql.dat" ]; then
	echo "apt_maxid.sql.dat file exists"
fi
if [ -f "/tmp/log_maxid.sql.dat" ]; then
	echo "log_maxid.sql.dat file exists"
fi
BLOCK
if [ -f "/tmp/apt_maxid.sql.dat" ] && [ -f "/tmp/log_maxid.sql.dat" ]; then

	while read line
	do
		apt_maxid=$line
	done < /tmp/apt_maxid.sql.dat

	while read line
	do
		log_maxid=$line
	done < /tmp/log_maxid.sql.dat
fi
:<<BLOCK
echo $apt_maxid
echo $log_maxid
BLOCK
mysql -u${DB_USER} -p${DB_PASSWD} -D${DB_NAME} -e "ALTER TABLE hotel_apt AUTO_INCREMENT=${apt_maxid}; ALTER TABLE hotel_apt_logs AUTO_INCREMENT=${log_maxid};"
