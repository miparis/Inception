# Documentación del Bloque 1: Entorno Base y Conceptos Clave

## 1. Infraestructura

* **Contenedor vs. Máquina Virtual:** Un contenedor es un paquete de software ligero que incluye código, herramientas y dependencias, compartiendo el núcleo (kernel) del sistema operativo anfitrión. Una Máquina Virtual (VM) emula un hardware y un sistema operativo completo con su propio núcleo, consumiendo muchos más recursos y tiempo de arranque.
* **MariaDB:** Sistema de gestión de bases de datos relacional. En esta arquitectura, actúa como el almacén persistente interno (completamente aislado del exterior) donde se guardan los usuarios y la configuración del sitio web.
* **WordPress:** Sistema de gestión de contenidos (CMS) ejecutado sobre PHP-FPM. Procesa la lógica web de forma aislada e interactúa constantemente con MariaDB.
* **NGINX:** Servidor web que actúa como proxy inverso y única puerta de entrada a la infraestructura mediante el puerto 443. Se encarga de cifrar el tráfico con los protocolos TLSv1.2/TLSv1.3 y reenviar las peticiones seguras al contenedor de WordPress.

## 2. Redirección del Dominio Local (`/etc/hosts`)

Al mapear `miparis.42.fr` a `127.0.0.1` (localhost) en el archivo `/etc/hosts`,hacemos que el tráfico web dirigido a ese dominio no salga a buscar un servidor DNS en internet, sino que se dirija directamente al puerto local (443) donde nuestro contenedor NGINX estará escuchando.

## 3. Creación de Volúmenes Nombrados (`/home/miparis/data/...`)

Para asegurar que la base de datos y los archivos de la web persistan, el proyecto exige usar volúmenes nombrados de Docker vinculados a la ruta física `/home/login/data` en la máquina anfitriona. Así, cualquier cambio interno en rutas como `/var/lib/mysql` se reflejará físicamente en el disco duro del host de forma segura. Los mismos son creados al momento de compilar, creando las carpetas especificas para cada volumen en la ruta específicada.

## 4. Estructura de Carpetas del Proyecto

Separar los archivos de configuración (`conf`) y los scripts de inicialización (`tools`) en el directorio `srcs/requirements/` permite que Docker Compose construya cada imagen de forma modular, independiente y ordenada, facilitando el mantenimiento y cumpliendo con las normas de entrega.

## 5. Gestión de Variables y Seguridad (`.env` y `.gitignore`)

El uso estricto de variables de entorno inyectadas por Docker Compose evita tener que escribir ("hardcodear") contraseñas directamente en el código fuente, lo cual es motivo de suspenso automático por brecha de seguridad. 

El archivo `.gitignore` bloquea la subida del archivo `.env` al repositorio. La configuración del `.env` queda así:

```ini
DOMAIN_NAME=miparis.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_PASSWORD=tu_password_db
MYSQL_ROOT_PASSWORD=tu_password_root
WP_TITLE=Inception_42
WP_ADMIN_USER=master_wp
WP_ADMIN_PASSWORD=tu_password_wp_admin
WP_ADMIN_EMAIL=master@student.42.fr
WP_USER=miparis
WP_EMAIL=miparis@student.42.fr
WP_USER_PASSWORD=tu_password_wp_user
```
---

# Servicio MariaDB

## 1. Conceptos Fundamentales

* **¿Qué es una Imagen de Docker?**
  Una imagen es una plantilla inmutable y de solo lectura que contiene el sistema operativo, las herramientas y las configuraciones base. Si un contenedor es la "casa" donde ocurren los procesos, la imagen es el "plano". El subject prohíbe usar imágenes prefabricadas (como la de MariaDB oficial), obligando a escribir nuestros propios "planos" (`Dockerfile`) partiendo de una imagen base limpia de Debian o Alpine.

* **¿Cómo funciona la red interna de Docker?**
  Docker crea un puente virtual (una red privada) que aísla los contenedores del exterior. La comunicación funciona gracias a un servidor DNS interno: un contenedor se comunica con otro simplemente usando su nombre (ej. `mariadb:3306`). Ningún servicio externo puede acceder a esta red salvo que abramos un puerto explícito hacia el host (lo cual solo haremos con NGINX en el puerto 443).

## 2. ¿Que se debe hacer con MariaDB?

* Construir desde cero el contenedor de la base de datos MariaDB usando Debian, abrimos sus puertos a la red interna y creamos un script para inyectar automáticamente nuestros usuarios y contraseñas.
* Para cumplir la norma estricta de no dejar contraseñas "hardcodeadas" en el código (se usan las del `.env`) y para asegurar que el proceso se ejecute legítimamente en primer plano (PID 1) sin usar trucos prohibidos como `tail -f` o bucles infinitos.
* Al levantar el contenedor, este ejecuta un script temporal que enciende MariaDB, crea la base de datos y configura los permisos. Luego lo apaga y usa el comando `exec` para ceder el control absoluto al demonio de la base de datos para que corra en primer plano. Sus archivos internos (`/var/lib/mysql`) persisten gracias al volumen en `/home/miparis/data/mariadb`.

## 3. Funciones especificads de cada .conf y .sh

### Archivo de Configuración (`50-server.cnf`)
* `[mysqld]`: Inicia el bloque de configuración del servidor.
* `user = mysql`: Ejecuta el servicio de forma segura bajo el usuario "mysql".
* `pid-file, socket, basedir, datadir...`: Definen las rutas estándar del sistema. `datadir = /var/lib/mysql` es donde MariaDB guarda la información, que luego enlazaremos a nuestro volumen persistente en el host.
* `port = 3306`: Puerto en el que MariaDB escucha las peticiones de WordPress.
* `bind-address = 0.0.0.0`: Por defecto, MariaDB solo atiende a su propia máquina (localhost/127.0.0.1). Poner `0.0.0.0` obliga al servicio a aceptar conexiones de cualquier IP dentro de la red interna de Docker.
* `query_cache_size / log_error`: Optimización de memoria caché y ubicación de registros.

### Script de Inicialización (`mariadb.sh`)
* `#!/bin/bash`: Indica que el archivo debe ser interpretado por Bash.
* `service mariadb start` y `sleep 5`: Inicia el servicio temporalmente y le da tiempo para estar operativo.
* `mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"`: Crea la base de datos tomando el nombre oculto en nuestro archivo `.env`.
* `mysql -e "CREATE USER ..."` y `mysql -e "GRANT ALL PRIVILEGES ..."`: Crea nuestro usuario de base de datos y le da control total sobre la base de datos creada.
* `mysql -e "ALTER USER 'root'@'localhost' ..."`: Cambia la clave del superusuario (`root`) para eliminar vulnerabilidades de seguridad.
* `mysql -e "FLUSH PRIVILEGES;"`: Aplica los cambios de permisos inmediatamente.
* `mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown`: Apaga la instancia temporal de configuración.
* `exec mysqld_safe`: (MUY IMPORTANTE) Reemplaza el proceso bash por MariaDB nativo. Convierte a la base de datos en el proceso PID 1 del contenedor, manteniéndolo vivo en primer plano sin usar parches ilegales.

### Dockerfile
* `FROM debian:bullseye`: Usa la penúltima versión estable de Debian como base.
* `RUN apt update -y && ... install mariadb-server -y`: Instala limpiamente MariaDB desde los repositorios de Debian.
* `COPY conf/50-server.cnf ...`: Sobrescribe la configuración por defecto con nuestro archivo personalizado.
* `COPY tools/mariadb.sh ...` y `RUN chmod +x ...`: Copia el script al contenedor y le asegura permisos de ejecución.
* `EXPOSE 3306`: Documenta y prepara el puerto 3306 para la red interna.
* `ENTRYPOINT ["/mariadb.sh"]`: Define el script como el único comando que se ejecutará al iniciar el contenedor.

# WordPress y PHP-FPM

## 1. Conceptos Fundamentales

* **PHP-FPM (FastCGI Process Manager):** Es el motor que procesa el código escrito en PHP. Dado que WordPress está programado en PHP, necesita este motor para funcionar. NGINX (el servidor web) no entiende PHP por sí solo, así que le enviará las peticiones a PHP-FPM, este ejecutará el código y le devolverá la página web ya renderizada en HTML.
* **WP-CLI (WordPress Command Line Interface):** Es una herramienta oficial que permite instalar, configurar y gestionar WordPress completamente desde la terminal, sin necesidad de abrir un navegador web. Es clave en nuestro proyecto porque necesitamos automatizar la instalación mediante un script.
* **Condición de Carrera (Race Condition) y "Ping":** Al ejecutar `docker-compose up`, todos los contenedores arrancan casi a la vez. MariaDB necesita varios segundos para iniciar su proceso y abrir su puerto. Si WordPress intenta instalarse antes de que MariaDB esté lista, la instalación fallará y el contenedor morirá. Para evitarlo, usamos un bucle (un "ping" constante a la base de datos) que pausa el script de WordPress hasta que MariaDB responda.

## 2. ¿Que se debe hacer con WordPress y PHP-FPM?

* Creamos un contenedor dedicado exclusivamente a ejecutar PHP y alojar los archivos de WordPress. Configuramos PHP-FPM para que escuche peticiones externas en el puerto 9000 y creamos un script que automatiza la instalación de la web y la creación de sus usuarios.
* Se exige obligatoriamente que WordPress y NGINX estén en contenedores separados. Además, nos exige crear dos usuarios específicos (cuidando que el administrador no tenga la palabra "admin") y prohíbe usar claves estáticas, obligándonos a leer el archivo `.env`.
* Cuando arranca el contenedor, el script espera pacientemente a MariaDB. Una vez que la base de datos está online, el script comprueba si WordPress ya está instalado. Si no lo está, lo descarga, inyecta las variables del `.env` para conectarlo a la base de datos, y crea los perfiles de usuario. Finalmente, usa `exec` para ceder el control al motor PHP-FPM, manteniéndolo en primer plano (PID 1).

## 3.  Funciones especificads de cada .conf y .sh

### Archivo de Configuración de PHP-FPM (`www.conf`)

* `[www]`: Define un grupo de procesos (pool) para procesar las peticiones web.
* `user / group = www-data`: Ejecuta los procesos bajo el usuario estándar de servidores web por motivos de seguridad.
* `listen = 9000`: Por defecto, PHP escucha en un archivo interno inalcanzable desde otros contenedores. Al poner `9000`, abrimos un puerto de red para que el contenedor NGINX pueda enviarle el tráfico.
* `clear_env = no`: **Crítico.** Por razones de seguridad, PHP suele limpiar (ignorar) las variables de entorno del sistema. Al poner `no`, le permitimos leer las contraseñas inyectadas desde nuestro `.env`.

### Script de Inicialización (`wordpress.sh`)

* `mkdir -p /var/www/wordpress`: Crea la ruta oficial donde vivirá la web (y que luego conectaremos a nuestro volumen del host).
* `while ! mariadb -h mariadb ...`: El famoso "ping". Intenta conectarse a la base de datos `mariadb`. Si falla, duerme 3 segundos (`sleep 3`) y repite el proceso hasta tener éxito.
* `wp core download --allow-root`: Descarga los archivos limpios de WordPress. La bandera `--allow-root` es necesaria porque estamos ejecutando el script como el superusuario del contenedor.
* `wp config create ...`: Genera el archivo `wp-config.php` vinculando los parámetros `--dbname`, `--dbuser` y `--dbpass` con nuestras variables seguras.
* `wp core install ...`: Instala la base de datos de WordPress y genera el usuario administrador (leyendo `$WP_ADMIN_USER`, que verificamos que no contenga la palabra "admin").
* `wp user create ...`: Crea el segundo usuario regular que exige el subject, asignándole el rol de "autor".
* `exec /usr/sbin/php-fpm7.4 -F`: Reemplaza el proceso bash por el de PHP-FPM. La bandera `-F` (Foreground) fuerza a PHP a quedarse en primer plano (como PID 1), evitando que el contenedor muera.

### Dockerfile

* `FROM debian:bullseye`: Usa la base permitida por el subject.
* `RUN apt install ... wget curl php7.4 php7.4-fpm php7.4-mysql mariadb-client`: Instala el motor PHP, el conector entre PHP y MySQL, y el cliente de MariaDB necesario para hacer el "ping".
* `wget ... wp-cli.phar ... mv ... /usr/local/bin/wp`: Descarga la herramienta WP-CLI y la mueve a una ruta global del sistema operativo para poder usar el comando `wp`.
* `COPY conf/www.conf ...`: Reemplaza la configuración por defecto por nuestro archivo que abre el puerto 9000.
* `EXPOSE 9000`: Documenta que el contenedor recibe tráfico en este puerto.
* `ENTRYPOINT ["/wordpress.sh"]`: Define nuestro script de bash como el comando principal del contenedor.

# NGINX y Seguridad TLS

## 1. Conceptos Fundamentales
*   **NGINX:** Es el servidor web que actúa como proxy inverso. Es la única puerta de entrada a nuestra infraestructura. Recibe las peticiones del exterior, comprueba que sean seguras y las redirige al contenedor de WordPress.
*   **SSL/TLS (Secure Sockets Layer / Transport Layer Security):** Protocolo criptográfico que cifra los datos entre el navegador del usuario y el servidor. El proyecto exige utilizar específicamente TLSv1.2 o TLSv1.3.
*   **Certificado Autofirmado (Self-signed):** Como la infraestructura es local, generamos nuestro propio certificado con OpenSSL. El cifrado es real y efectivo, aunque los navegadores mostrarán una advertencia inicial de seguridad al no estar firmado por una Entidad Certificadora (CA) externa.

## 2. Configuración de NGINX (`nginx.conf`)
*   `listen 443 ssl`: NGINX solo escucha en el puerto HTTPS (443), bloqueando el tráfico no cifrado por el puerto 80.
*   `ssl_certificate` y `ssl_certificate_key`: Apuntan a las rutas donde el Dockerfile guardó los certificados generados.
*   `ssl_protocols TLSv1.2 TLSv1.3`: Cumplimiento estricto del *subject* de 42, deshabilitando versiones antiguas e inseguras de TLS/SSL.
*   `fastcgi_pass wordpress:9000`: La directiva clave. NGINX no ejecuta PHP; cuando llega una petición para un archivo `.php`, NGINX se la reenvía por la red interna de Docker al contenedor de WordPress en el puerto 9000.

## 3. Construcción del Contenedor (`Dockerfile`)
*   **`openssl req -x509 ...`**: Este comando genera de forma no interactiva (sin hacer preguntas en consola) una clave privada RSA de 2048 bits y un certificado válido por 365 días.
*   **El parámetro `-subj`**: Rellena automáticamente los datos del certificado (País: ES, Organización: 42, Common Name: miparis.42.fr).
*   **Regla del PID 1 (`daemon off;`)**: Por defecto, NGINX se ejecuta en segundo plano. El comando `CMD ["nginx", "-g", "daemon off;"]` lo fuerza a ejecutarse en primer plano, evitando que el contenedor se apague inmediatamente tras arrancar.

# Docker Compose

## 1. Conceptos Fundamentales
*   **Docker Compose (`docker-compose.yml`):** Es la herramienta que permite definir y ejecutar aplicaciones Docker multi-contenedor. En lugar de levantar cada contenedor por separado, usamos este archivo YAML como "plano maestro" para indicar redes, volúmenes, puertos y el orden de encendido.
*   **YAML (.yml):** Formato de serialización de datos muy estricto con la indentación (espacios, no tabulaciones).

## 2. Directivas Clave del archivo YAML
*   `depends_on`: Establece jerarquía. WordPress espera a MariaDB, y NGINX espera a WordPress. Evita que los servicios intenten conectarse antes de que la base de datos esté lista.
*   `networks`: Todos los contenedores están unidos a `inception` (tipo bridge). Esto aísla el proyecto del exterior y permite que los contenedores se comuniquen usando su nombre (ej. `mariadb`) gracias al DNS interno de Docker.
*   `volumes` (Host Bind Mounts): Cumpliendo el *subject*, se vinculan directorios virtuales (`/var/lib/mysql` y `/var/www/wordpress`) a directorios físicos del host (`/home/miparis/data/...`). Esto garantiza la persistencia absoluta de los datos aunque los contenedores se destruyan.

---

# Automatización (Makefile)

## 1. Reglas Principales de Docker
*   `up`: Ejecuta `docker-compose up -d --build`. Construye las imágenes si hay cambios y levanta los contenedores en modo *detached* (segundo plano).
*   `down`: Ejecuta `docker-compose down`. Detiene los contenedores de forma limpia sin borrar los datos ni las imágenes.
*   `clean`: Añade las banderas `-v` y `--rmi all` al comando down para borrar volúmenes virtuales, redes e imágenes base descargadas.
*   `fclean`: Hace un borrado profundo. Elimina físicamente el contenido de las carpetas locales de persistencia (`/home/miparis/data/`) mediante `rm -rf` y ejecuta `docker system prune -af` para limpiar cualquier caché residual del motor de Docker.
