#!/bin/bash

# We init MariaDB on a second plane temporarly
service mariadb start 
sleep 5

# Configure users and data bases reading the variables at .env
mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
mysql -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mysql -e "FLUSH PRIVILEGES;"

# Shut down the service temporarly authenticating with the new root key
mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown

# Change the actual process for MariaDB in PID 1
exec mysqld_safe