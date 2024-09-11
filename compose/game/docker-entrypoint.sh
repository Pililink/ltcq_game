#!/bin/bash
# MySQL 数据目录的路径
DATA_DIR="/data/mysql"

# 设置默认的 root 密码
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-123456}

# 检查是否已初始化
if [ ! -d "$DATA_DIR/mysql" ]; then
    # 初始化mysql
    echo "Initializing MySQL database..."
    /usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=$DATA_DIR

    # 初始化数据
    service mysql start
    # 设置 root 默认密码为 123456
    echo "Setting root password to $MYSQL_ROOT_PASSWORD"
    mysql -uroot -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_PASSWORD}');"
    # 为 root 用户启用远程访问
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;"
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"

    # 执行初始化 SQL 文件
    if [ -d "$INIT_SQL_DIR" ]; then
      for sql_file in "$INIT_SQL_DIR"/*.sql; do
        echo "Executing $sql_file..."
        mysql -uroot -p${MYSQL_ROOT_PASSWORD} < "$sql_file"
      done
    fi

    # 创建标志文件表示初始化已完成
    touch "$DATA_DIR/mysql_initialized"
else
    echo "MySQL database already initialized."
fi
# 更新IP地址

# 启动服务
service nginx start
service php5.6-fpm start
service mysql start

# 启动游戏后端服务
cd /server/s1
./run.sh

# 保持容器运行
tail -f /dev/null
