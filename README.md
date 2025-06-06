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
   git clone --recurse-submodules https://github.com/yourusername/vps-gbacso.git
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

Run the main script with your desired options:

```sh
cd docker
./start_containers.sh --mariadb-password <mariadb_root_pw> \
                      --frappe-password <frappe_admin_pw> \
                      --letsencrypt-email <your_email> \
                      --sites site1.com,site2.com \
                      --docker-account <dockerhub_user> \
                      --image-name <erpnext_image> \
                      --image-tag <tag> \
                      [--lan]
```

**Example:**

```sh
./start_containers.sh --mariadb-password mypass --frappe-password adminpass \
  --letsencrypt-email user@example.com --sites erpnext.bacso.ch \
  --docker-account gaeba95 --image-name customappfrappe --image-tag latest
```

### Build Custom ERPNext Image

```sh
cd docker/erpnext
./builds_apps_docker_image.sh --docker-account gaeba95 --image-name customappfrappe --image-tag latest
```

---

## Project Structure

```sh
vps-gbacso/
├── .gitignore
├── .gitmodules
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
    │   └── frappe_docker/   # (git submodule)
    ├── portainer/
    │   └── docker-compose.yml
    ├── resume-gbacso/
    │   └── docker-compose.yml
    ├── traefik/
    │   ├── compose.traefik-ssl.yaml
    │   ├── compose.traefik.yaml
    │   ├── deploy_traefik.sh
    │   └── traefik.env
    └── wordpress/
        └── docker-compose.yml
```

---

## File & Folder Explanations

### Root

- **.gitignore**: Ignores OS and editor-specific files.
- **.gitmodules**: Declares the `frappe_docker` submodule for ERPNext.
- **README.md**: This documentation.
- **install_server.sh**: Installs Docker Engine, CLI, and dependencies on Ubuntu.

### docker/

- **start_containers.sh**: Main script to start all services (Traefik, Portainer, WordPress, Resume, ERPNext). Handles argument parsing and orchestration.
- **erpnext/**: ERPNext deployment scripts and configuration.
  - **builds_apps_docker_image.sh**: Builds and pushes a custom ERPNext Docker image with selected apps.
  - **create_dockercompose_frappe.sh**: Generates Docker Compose files for ERPNext based on environment and arguments.
  - **deploy_erpnext.sh**: Deploys ERPNext stack, creates sites, installs apps.
  - **set_frappe_docker_repo_arm64.sh**: Builds ERPNext Docker images for ARM64.
  - **compose/**: Docker Compose files for ERPNext (x86 and ARM64).
  - **env/**: Environment variable files for ERPNext and MariaDB.
  - **frappe_docker/**: [frappe/frappe_docker](https://github.com/frappe/frappe_docker) submodule for official ERPNext Docker setup.
- **portainer/**: Docker Compose file for Portainer UI.
- **resume-gbacso/**: Docker Compose file for your resume static site.
- **traefik/**: Traefik reverse proxy configuration.
  - **compose.traefik.yaml**: Base Traefik Compose file.
  - **compose.traefik-ssl.yaml**: SSL/Let's Encrypt configuration for Traefik.
  - **deploy_traefik.sh**: Script to deploy Traefik with or without LAN mode.
  - **traefik.env**: Environment variables for Traefik (domains, email, credentials).
- **wordpress/**: Docker Compose file for WordPress.

---

## Examples

**Start all services with interactive prompts:**

```sh
cd docker
./start_containers.sh
```

**Deploy only ERPNext (after building image):**

```sh
cd docker/erpnext
./deploy_erpnext.sh --mariadb-password mypass --frappe-password adminpass --letsencrypt-email user@example.com --sites erpnext.bacso.ch
```

---

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
