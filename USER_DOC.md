# User Documentation

## Basic Usage & Controls
To start the infrastructure, run the following command at the root of the project:
`make` or `make up`

To stop the services safely without losing data:
`make down`

## Accessing the Website & Admin Panel
* **Website:** Open a web browser and navigate to `https://miparis.42.fr`. You will need to accept the self-signed SSL certificate warning.
* **Admin Panel:** Navigate to `https://miparis.42.fr/wp-admin`. 

## Managing Credentials
All user credentials, database names, and passwords are secure and managed via a local `.env` file located in the `srcs/` directory. This file is ignored by Git and must not be shared. To change a user's password, modify the `.env` file and rebuild the containers using `make re`.

## Basic Checks
To verify that all services are running properly, execute:
`docker ps`
You should see three containers (nginx, wordpress, mariadb) with an "Up" status.