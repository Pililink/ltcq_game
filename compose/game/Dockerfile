FROM ubuntu:20.04

# 环境变量设置
ENV DEBIAN_FRONTEND=noninteractive \
    MYSQL_VERSION=5.6.51 \
    INIT_SQL_DIR=/docker-entrypoint-initdb.d \
    MYSQL_DATA_DIR=/data/mysql \
    TZ=Asia/Shanghai


# 更新软件源并安装所需的软件包
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    libncurses5-dev \
    libssl-dev \
    bison \
    wget \
    curl \
    tzdata \
    lsb-release \
    apt-transport-https \
    libaio-dev \
    libboost-dev \
    nginx \
    software-properties-common && \
    add-apt-repository ppa:ondrej/php && apt-get update && apt-get install -y --no-install-recommends \
    php5.6 \
    php5.6-fpm \
    php5.6-mysql \
    php5.6-cli \
    php5.6-common \
    php5.6-json \
    php5.6-opcache \
    php5.6-readline && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 下载并编译安装 MySQL 5.6
WORKDIR /usr/src
RUN wget https://downloads.mysql.com/archives/get/p/23/file/mysql-${MYSQL_VERSION}.tar.gz && \
    tar -xzf mysql-${MYSQL_VERSION}.tar.gz && \
    mkdir -p mysql-${MYSQL_VERSION}/bld && \
    cd mysql-${MYSQL_VERSION}/bld && \
    cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
    -DMYSQL_DATADIR=${MYSQL_DATA_DIR} \
    -DSYSCONFDIR=/etc && \
    make -j$(nproc) && make install && \
    cp /usr/local/mysql/lib/libmysqlclient* /usr/lib/ && \
    ldconfig && \
    rm -rf /usr/src/mysql*

# 设置 MySQL 用户组、权限和配置文件
RUN groupadd mysql && useradd -r -g mysql mysql && \
    cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql && \
    chmod +x /etc/init.d/mysql && \
    update-rc.d mysql defaults

# 设置环境变量
ENV PATH="/usr/local/mysql/bin:/usr/local/mysql/lib:$PATH"

# 复制项目文件和初始化脚本
COPY ./conf/nginx/default.conf /etc/nginx/sites-available/default
COPY ./update_address.sh /update_address.sh
COPY ./init-sql /docker-entrypoint-initdb.d
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    apt-get purge -y --auto-remove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc /usr/share/doc-base

# 开放 Nginx 和 MySQL 的默认端口
EXPOSE 80 3306 9001

# 启动入口脚本
CMD ["/usr/local/bin/docker-entrypoint.sh"]
