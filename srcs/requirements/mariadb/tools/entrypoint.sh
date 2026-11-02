#!/bin/sh
set -e

install -d -o mysql -g mysql /run/mysqld
install -d -o mysql -g mysql /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal

    db_password=$(sed -e 's/\\/\\\\/g' -e "s/'/''/g" /run/secrets/db_password)
    root_password=$(sed -e 's/\\/\\\\/g' -e "s/'/''/g" /run/secrets/db_root_password)

    cat > /run/mysqld/init.sql <<EOSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_password}';
CREATE DATABASE \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
EOSQL

    chown mysql:mysql /run/mysqld/init.sql

    exec mariadbd \
        --user=mysql \
        --port="$MYSQL_PORT" \
        --init-file=/run/mysqld/init.sql
fi

exec mariadbd --user=mysql --port="$MYSQL_PORT"