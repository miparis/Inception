# Documentación del Bloque 1: Entorno Base y Conceptos Clave

## 1. Conceptos Fundamentales de la Infraestructura

* **Contenedor vs. Máquina Virtual:** Un contenedor es un paquete de software ligero que incluye código, herramientas y dependencias, compartiendo el núcleo (kernel) del sistema operativo anfitrión. Una Máquina Virtual (VM) emula un hardware y un sistema operativo completo con su propio núcleo, consumiendo muchos más recursos y tiempo de arranque.
* **MariaDB:** Sistema de gestión de bases de datos relacional. En esta arquitectura, actúa como el almacén persistente interno (completamente aislado del exterior) donde se guardan los usuarios y la configuración del sitio web.
* **WordPress:** Sistema de gestión de contenidos (CMS) ejecutado sobre PHP-FPM. Procesa la lógica web de forma aislada e interactúa constantemente con MariaDB.
* **NGINX:** Servidor web que actúa como proxy inverso y única puerta de entrada a la infraestructura mediante el puerto 443. Se encarga de cifrar el tráfico con los protocolos TLSv1.2/TLSv1.3 y reenviar las peticiones seguras al contenedor de WordPress.

## 2. Redirección del Dominio Local (`/etc/hosts`)

Al mapear `miparis.42.fr` a `127.0.0.1` (localhost) en el archivo `/etc/hosts`, engañamos al sistema operativo. Esto provoca que el tráfico web dirigido a ese dominio no salga a buscar un servidor DNS en internet, sino que se dirija directamente al puerto local (443) donde nuestro contenedor NGINX estará escuchando.

## 3. Creación de Volúmenes Nombrados (`/home/miparis/data/...`)

Los contenedores son efímeros por naturaleza (si se destruye el contenedor, se pierden sus datos). Para asegurar que la base de datos y los archivos de la web persistan, el proyecto exige usar volúmenes nombrados de Docker vinculados a la ruta física `/home/login/data` en la máquina anfitriona. Así, cualquier cambio interno en rutas como `/var/lib/mysql` se reflejará físicamente en el disco duro del host de forma segura.

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

# Cuidado !!
Falsa sensación de seguridad con rutas locales: El proyecto exige /home/login/data. Si tu usuario de Ubuntu se llama admin en lugar de miparis, y hardcodeas la ruta /home/admin/data en tu docker-compose.yml, el proyecto fallará inmediatamente en la evaluación oficial.   

# Documentación del Bloque 2: Servicio MariaDB

## 1. Conceptos Fundamentales

* **¿Qué es una Imagen de Docker?**
  Una imagen es una plantilla inmutable y de solo lectura que contiene el sistema operativo, las herramientas y las configuraciones base. Si un contenedor es la "casa" donde ocurren los procesos, la imagen es el "plano". El subject prohíbe usar imágenes prefabricadas (como la de MariaDB oficial), obligando a escribir nuestros propios "planos" (`Dockerfile`) partiendo de una imagen base limpia de Debian o Alpine.

* **¿Cómo funciona la red interna de Docker?**
  Docker crea un puente virtual (una red privada) que aísla los contenedores del exterior. La comunicación funciona gracias a un servidor DNS interno: un contenedor se comunica con otro simplemente usando su nombre (ej. `mariadb:3306`). Ningún servicio externo puede acceder a esta red salvo que abramos un puerto explícito hacia el host (lo cual solo haremos con NGINX en el puerto 443).

## 2. Resumen del Bloque 2: MariaDB

* **¿Qué hicimos?** Construimos desde cero el contenedor de la base de datos MariaDB usando Debian, abrimos sus puertos a la red interna y creamos un script para inyectar automáticamente nuestros usuarios y contraseñas.
* **¿Por qué lo hicimos?** Para cumplir la norma estricta de no dejar contraseñas "hardcodeadas" en el código (se usan las del `.env`) y para asegurar que el proceso se ejecute legítimamente en primer plano (PID 1) sin usar trucos prohibidos como `tail -f` o bucles infinitos.
* **¿Cómo funciona por detrás?** Al levantar el contenedor, este ejecuta un script temporal que enciende MariaDB, crea la base de datos y configura los permisos. Luego lo apaga y usa el comando `exec` para ceder el control absoluto al demonio de la base de datos para que corra en primer plano. Sus archivos internos (`/var/lib/mysql`) persisten gracias al volumen en `/home/miparis/data/mariadb`.

## 3. Análisis línea por línea de los archivos

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

### El Dockerfile
* `FROM debian:bullseye`: Usa la penúltima versión estable de Debian como base.
* `RUN apt update -y && ... install mariadb-server -y`: Instala limpiamente MariaDB desde los repositorios de Debian.
* `COPY conf/50-server.cnf ...`: Sobrescribe la configuración por defecto con nuestro archivo personalizado.
* `COPY tools/mariadb.sh ...` y `RUN chmod +x ...`: Copia el script al contenedor y le asegura permisos de ejecución.
* `EXPOSE 3306`: Documenta y prepara el puerto 3306 para la red interna.
* `ENTRYPOINT ["/mariadb.sh"]`: Define el script como el único comando que se ejecutará al iniciar el contenedor.