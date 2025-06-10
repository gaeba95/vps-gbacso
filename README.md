# VPS-Gbacso: Dockerized ERPNext, Traefik, Portainer, WordPress, and Resume Stack

## Overview

This project provides a set of scripts and Docker Compose files to deploy a production-ready stack including:

- **ERPNext** (with custom image support)
- **Traefik** (reverse proxy with SSL)
- **Portainer** (Docker management UI)
- **WordPress**
- **Resume static site**

All services are orchestrated via Docker Compose, with easy configuration and deployment scripts.

---

## Prerequisites

- **Ubuntu Server** (tested on 20.04+)
- **Docker Engine** and **Docker Compose** (install script provided)
- **git** (for cloning and submodules)
- **bash** shell

---

## Installation

1. **Clone the repository:**

   ```sh
   git clone --recurse-submodules https://github.com/gaeba95/vps-gbacso.git
   cd vps-gbacso
   ```

2. **Install Docker and dependencies:**

   ```sh
   bash install_server.sh
   ```

3. **Initialize submodules (if not already done):**

   ```sh
   git submodule update --init --recursive
   ```

---

## Usage

### Start All Services

You can start the entire stack using the main script with your desired options as command-line arguments. If any required argument is omitted, the script will prompt you interactively.

```sh
cd docker
./start_containers.sh [OPTIONS]
```

**Key Options:**

- `--mariadb-password <password>`: Set MariaDB root password (ERPNext)
- `--frappe-password <password>`: Set Frappe admin password (ERPNext)
- `--letsencrypt-email <email>`: Email for Let's Encrypt SSL
- `--sites <sites>`: Comma-separated list of ERPNext sites to create
- `--docker-account <account>`: Docker Hub account for ERPNext images
- `--image-name <name>`: ERPNext Docker image name
- `--image-tag <tag>`: ERPNext Docker image tag
- `--lan`: Enable LAN mode (uses LAN-specific compose file)
- `--traefik-domain <domain>`: Traefik main domain
- `--traefik-wildcard-domain <domain>`: Traefik wildcard domain
- `--traefik-email <email>`: Traefik notification email
- `--traefik-hashed-password <password>`: Hashed password for Traefik dashboard
- `--cf-dns-api-token <token>`: Cloudflare DNS API token (for DNS challenge)
- `--wp-db-root-password <password>`: WordPress DB root password
- `--wp-db-password <password>`: WordPress DB user password

Run `./start_containers.sh --help` for the full list of options.

---

## Examples

**Start all services with all options provided:**

```sh
cd docker
./start_containers.sh \
  --mariadb-password mypass \
  --frappe-password adminpass \
  --letsencrypt-email user@example.com \
  --sites site1.com,site2.com \
  --docker-account yourdockeraccount \
  --image-name customappfrappe \
  --image-tag latest \
  --traefik-domain example.com \
  --traefik-wildcard-domain '*.example.com' \
  --traefik-email admin@example.com \
  --traefik-hashed-password 'user:$apr1$...' \
  --cf-dns-api-token xxxxxxxx \
  --wp-db-root-password wp_root_pass \
  --wp-db-password wp_user_pass
```

**Start all services and provide missing options interactively:**

```sh
cd docker
./start_containers.sh
```

**Build a custom ERPNext Docker image:**

```sh
cd docker/erpnext
./builds_apps_docker_image.sh --docker-account yourdockeraccount --image-name customappfrappe --image-tag latest
```

---

## Project Structure

```sh
vps-gbacso/
├── .gitignore
├── .gitmodules
├── .github/
│   └── workflows/
│       └── docker-image.yml
├── README.md
├── install_server.sh
└── docker/
  ├── start_containers.sh
  ├── erpnext/
  │   ├── builds_apps_docker_image.sh
  │   ├── create_dockercompose_frappe.sh
  │   ├── deploy_erpnext.sh
  │   ├── set_frappe_docker_repo_arm64.sh
  │   ├── compose/
  │   │   ├── compose.yaml
  │   │   └── compose_arm64.yaml
  │   ├── env/
  │   │   ├── erpnext-one.env
  │   │   └── mariadb.env
  │   └── frappe_docker/
  ├── portainer/
  │   └── docker-compose.yml
  ├── resume-gbacso/
  │   └── docker-compose.yml
  ├── traefik/
  │   ├── compose.traefik.yaml
  │   ├── compose.traefik-ssl.yaml
  │   ├── deploy_traefik.sh
  │   └── traefik.env
  └── wordpress/
    └── docker-compose.yml
```

---

## File & Folder Explanations

### Root

- **.gitignore**: Specifies files and directories to be ignored by git.
- **.gitmodules**: Lists git submodules, including the ERPNext Docker setup.
- **README.md**: Project documentation and usage instructions.
- **install_server.sh**: Automated script to install Docker, Docker Compose, and dependencies on Ubuntu.

### .github/workflows/

- **docker-image.yml**: GitHub Actions workflow for building Docker images.

### docker/

- **start_containers.sh**: Orchestrates the startup of all stack services with configurable options.
- **erpnext/**: ERPNext deployment and configuration scripts.
  - **builds_apps_docker_image.sh**: Builds and optionally pushes a custom ERPNext Docker image.
  - **create_dockercompose_frappe.sh**: Generates ERPNext Docker Compose files based on environment and arguments.
  - **deploy_erpnext.sh**: Deploys ERPNext, manages site creation, and app installation.
  - **set_frappe_docker_repo_arm64.sh**: Prepares ERPNext Docker images for ARM64 architecture.
  - **compose/**: Contains Docker Compose files for ERPNext (x86 and ARM64).
  - **env/**: Environment variable files for ERPNext and MariaDB services.
  - **frappe_docker/**: Submodule with the official ERPNext Docker setup.
- **portainer/**: Contains the Docker Compose file for deploying Portainer UI.
- **resume-gbacso/**: Docker Compose file for deploying the static resume site.
- **traefik/**: Traefik reverse proxy configuration and deployment scripts.
  - **compose.traefik.yaml**: Base configuration for Traefik.
  - **compose.traefik-ssl.yaml**: SSL/Let's Encrypt configuration for Traefik.
  - **deploy_traefik.sh**: Script to deploy Traefik with optional LAN mode.
  - **traefik.env**: Environment variables for Traefik (domains, email, credentials).
- **wordpress/**: Docker Compose file for deploying WordPress.

## Notes

- All scripts are designed for **bash** and tested on Ubuntu.
- ERPNext is highly configurable via environment files and script arguments.
- The `frappe_docker` submodule is required for ERPNext deployment and image building.
- For production, ensure your `.env` files and secrets are secured.

---

## References

- [ERPNext Docker](https://github.com/frappe/frappe_docker)
- [Traefik](https://doc.traefik.io/traefik/)
- [Portainer](https://www.portainer.io/)
- [WordPress Docker](https://hub.docker.com/_/wordpress)

---

## License

MIT (or your preferred license)
