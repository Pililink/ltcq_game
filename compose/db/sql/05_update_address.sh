#!/bin/bash

# 读取环境变量
SERVER_ADDRESS=${SERVER_ADDRESS}
ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

# 动态生成 SQL 脚本并执行
mysql -u root -p$ROOT_PASSWORD -sBN --default-character-set=utf8  <<EOF
use globaldata;
truncate server;
truncate serverroute;

INSERT INTO globaldata.server 
(name, ip, port) 
VALUES('1区', '$SERVER_ADDRESS', '9002');

INSERT INTO globaldata.serverroute
(serverid, hostname, port, name, opentime, realid)
VALUES(1, '$SERVER_ADDRESS', 9002, '1区', '2020-06-08 13:00:00', 1);
EOF
