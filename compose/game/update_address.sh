#!/bin/bash

# 读取环境变量
SERVER_ADDRESS=${SERVER_ADDRESS}
ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

# 更新数据库中服务器地址
mysql -u root -p$ROOT_PASSWORD -sBN --default-character-set=utf8  <<EOF
use globaldata;

UPDATE globaldata.server
SET ip='$SERVER_ADDRESS'
WHERE id=1;

UPDATE globaldata.serverroute
SET hostname='$SERVER_ADDRESS'
WHERE id=1;
EOF

# 更新前端文件中服务器地址
# 
echo "update /config.php address"
sed -i "s|http://[0-9\.]\+:81/|http://${SERVER_ADDRESS}:81/|" /var/www/html/config.php

# /h5game/index.js
echo "update /index.js address"
sed -i "s|http://[0-9\.]\+:81/|http://${SERVER_ADDRESS}:81/|" /var/www/html/index.js
# /h5game/login.min.js
echo "update /login.min.js address"
sed -i "s|http://[0-9\.]\+:81/|http://${SERVER_ADDRESS}:81/|" /var/www/html/login.min.js
# /h5game/web/server_list/config.php
echo "update /web/server_list/config.php address"

sed -i "s|\$whitelist = array('[0-9\.]\+',);|\$whitelist = array('${SERVER_ADDRESS}',);|" /var/www/html/web/server_list/config.php
sed -i "s|'ip' => '[0-9\.]\+',|'ip' => '${SERVER_ADDRESS}',|" /var/www/html/web/server_list/config.php
sed -i "s|http://[0-9\.]\+:81/|http://${SERVER_ADDRESS}:81/|" /var/www/html/web/server_list/config.php
