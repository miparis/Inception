*This project has been created as part of the 42 cursus by miparis*

## Project Description
Inception is a System Administration project that aims to broaden knowledge of system administration by using Docker. The goal is to virtualize a complete personal infrastructure within a single Virtual Machine. 

**Use of Docker and Sources:** 
Docker is used to containerize each service individually, ensuring isolated and reproducible environments. The project sources include custom-written `Dockerfiles` using Debian 11 (Bullseye) as the penultimate stable base image, configuring NGINX (with TLS), WordPress (via php-fpm), and MariaDB from scratch without relying on pre-configured DockerHub images.

**Main Design Choices:**
* **One container per service:** Following microservices architecture principles.
* **No background processes:** All services are configured to run in the foreground (PID 1) to allow Docker's daemon to monitor their state properly.
* **Custom Bridge Network:** A dedicated internal network (`inception`) ensures that containers communicate securely using internal DNS, exposing only NGINX (port 443) to the outside world.

### Technical Comparisons

**1. Virtual Machines vs Docker**
* **Virtual Machines (VMs)** virtualize the hardware. They require a full guest Operating System (OS) to run on top of a hypervisor, making them heavy, resource-intensive, and slower to boot.
* **Docker** virtualizes the OS. Containers share the host's Linux kernel, containing only the application and its necessary binaries/libraries. This makes Docker lightweight, fast to start, and highly efficient.

**2. Secrets vs Environment Variables**
* **Docker Secrets** is a feature (mostly used in Docker Swarm) that securely encrypts sensitive data and mounts it directly into the container's memory space, never writing it to disk. 
* **Environment Variables**, which are used in this project via a `.env` file, inject values directly into the container's environment. While easier to set up, they are less secure for production since they can be exposed if someone inspects the container (`docker inspect`).

**3. Docker Network vs Host Network**
* **Host Network** (`network: host`) removes all network isolation between the container and the Docker host. The container uses the host's IP and networking directly, which can cause port conflicts and security risks.
* **Docker Network** (like the custom bridge used here) creates an isolated, private internal network. Services can safely communicate with each other using their container names as hostnames, completely isolated from external access unless explicitly mapped.

**4. Docker Volumes vs Bind Mounts**
* **Docker Volumes** are managed entirely by Docker and stored in a protected area of the host filesystem (usually `/var/lib/docker/volumes/`). They are the best choice for standard persistence.
* **Bind Mounts** link a specific, user-defined path on the host machine directly to a directory inside the container. This project strictly uses Bind Mounts (e.g., `/home/miparis/data/wordpress`) to ensure the evaluator can easily access, verify, and persist the data on the local VM filesystem.

## Instructions
1. Navigate to the project root where the `Makefile` is located.
2. Ensure you have Docker and Docker Compose installed.
3. Configure your local `.env` file inside the `srcs/` directory.
4. Run `make` to build and deploy the infrastructure.
5. Access the website at `https://miparis.42.fr`.

## References
* [Docker Documentation](https://docs.docker.com/)
* [NGINX Official Documentation](https://nginx.org/en/docs/)
* [WordPress Developer Resources](https://developer.wordpress.org/)
* [MariaDB Knowledge Base](https://mariadb.com/kb/en/)

## AI use explanation
AI was used exclusively as a thought partner and troubleshooting assistant during the development of this project. It helped in understanding Docker orchestration concepts, identifying syntax errors (e.g., in `www.conf`), and navigating Debian repository deprecations (`archive.debian.org`), while the code structure and implementation were manually checked and tested.