#!/bin/bash

# ensure dir exists and enter
mkdir -p /var/www/wordpress
cd /var/www/wordpress

# Wait for MariaDB to be ready to allow conections
# we use mariadb-admin ping with host 'mariadb' (the name of the service of docker-compose)
while ! mariadb -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "USE ${MYSQL_DATABASE};" > /dev/null 2>&1; do
    sleep 3
done

# ifnot installed, we donwload wordpress and configure
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    
    # 1. Download base files
    wp core download --allow-root

    # 2. Create wp-config.php matching it with our db
    wp config create --allow-root \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb:3306

    # 3. Install WordPress and create admin user
    wp core install --allow-root \
        --url=https://${DOMAIN_NAME} \
        --title="${WP_TITLE}" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL}

    # 4. Create normal user
    wp user create --allow-root ${WP_USER} ${WP_EMAIL} --user_pass=${WP_USER_PASSWORD} --role=author
fi

# Init PHP-FPM (-F) as principal process (PID 1)
exec /usr/sbin/php-fpm7.4 -F