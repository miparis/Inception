# Developer Documentation

## Prerequisites & Setup
* **Operating System:** Debian 11 (Bullseye) VM.
* **Dependencies:** `docker.io`, `docker-compose`, `make`.
* **Host Configuration:** The domain `miparis.42.fr` must be mapped to `127.0.0.1` in the `/etc/hosts` file.
* **Directories:** Local directories `/home/miparis/data/wordpress` and `/home/miparis/data/mariadb` must be created manually before deployment.

## Makefile Usage
The Makefile at the root of the repository acts as a wrapper for Docker Compose:
* `make` / `make up`: Builds the images and starts the containers in detached mode.
* `make down`: Stops and removes the containers.
* `make clean`: Stops containers and removes unused images and volumes.
* `make fclean`: Performs a deep clean, pruning the Docker system and physically deleting the local data in `/home/miparis/data/`.
* `make re`: Executes `fclean` followed by `up`.

## Docker Compose & Network
The infrastructure is defined in `srcs/docker-compose.yml`. 
* **Network:** A custom bridge network named `inception` is used. Containers communicate internally using their service names. Direct host networking (`network: host`) and legacy links (`links:`) are strictly avoided.
* **TLS:** NGINX handles incoming connections exclusively on port 443.

## Data Persistence
Data persistence is achieved using Docker Host Volumes. 
* Database files are bound to `/home/miparis/data/mariadb`.
* WordPress core files are bound to `/home/miparis/data/wordpress`.
This ensures that user posts and database states survive container deletion and system reboots.