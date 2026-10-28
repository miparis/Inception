FROM debian:bullseye

# update rpos to archive.debian.org as we need to use Debian Bullseye (Debian 11)
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i '/bullseye-updates/d' /etc/apt/sources.list

# Install NGINX and OpenSSL for certificates
RUN apt update -y && apt upgrade -y && \
    apt install nginx openssl -y

# Generate the SSL certificate selfsigned (data inputed through here)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/inception.key \
    -out /etc/ssl/certs/inception.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=42/CN=miparis.42.fr/UID=miparis"

# Copy our config file and replace NGINX default one
COPY conf/nginx.conf /etc/nginx/sites-available/default

EXPOSE 443

# Ejecute NGINX on PID 1
CMD ["nginx", "-g", "daemon off;"]