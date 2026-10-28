FROM debian:bullseye

# update rpos to archive.debian.org as we need to use Debian Bullseye (Debian 11)
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i '/bullseye-updates/d' /etc/apt/sources.list

# Instal PHP, extensions, MariaDB client and tools as curl/wget
RUN apt update -y && apt upgrade -y && \
    apt-get install -y wget curl php7.4 php7.4-fpm php7.4-mysql mariadb-client

# Install WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Create dirs for PHP-FPM
RUN mkdir -p /run/php

# Copy config file of PHP-FPM
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy start script
COPY tools/wordpress.sh /wordpress.sh
RUN chmod +x /wordpress.sh

# Allow as entry port 9000
EXPOSE 9000

# Entry
ENTRYPOINT ["/wordpress.sh"]