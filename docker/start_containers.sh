#!/bin/bash
# -----------------------------------------------------------------------------
# File: start_containers.sh
# Description: Script to start and deploy multiple Docker services including
#              Traefik, Portainer, WordPress, Resume, and ERPNext.
# Author: Gaetan Bacso
#
# Usage:
#   ./start_containers.sh [OPTIONS]
#
# Arguments:
#   --mariadb-password <password>          Set MariaDB root password
#   --frappe-password <password>           Set Frappe admin password
#   --letsencrypt-email <email>            Set email for Let's Encrypt
#   --sites <sites>                        Comma-separated list of ERPNext sites to create
#   --lan                                  Enable LAN mode (uses erpnext-one-lan compose file)
#   --docker-account <account>             Docker Hub account name for images
#   --image-name <name>                    Docker image name for ERPNext
#   --image-tag <tag>                      Docker image tag for ERPNext
#   --traefik-domain <domain>              Traefik domain
#   --traefik-wildcard-domain <domain>     Traefik wildcard domain
#   --traefik-email <email>                Traefik email
#   --traefik-hashed-password <password>   Traefik hashed password
#   --cf-dns-api-token <token>             Cloudflare DNS API token
#   --wp-db-root-password <password>       WordPress DB root password
#   --wp-db-password <password>            WordPress DB user password
#   --help, -h                             Show this help message
#
# Example:
#   ./start_containers.sh \
#     --mariadb-password mypass \
#     --frappe-password adminpass \
#     --letsencrypt-email user@example.com \
#     --sites site1.com,site2.com \
#     --lan \
#     --docker-account mydockeruser \
#     --image-name myerpnext \
#     --image-tag v1.0.0 \
#     --traefik-domain example.com \
#     --traefik-wildcard-domain '*.example.com' \
#     --traefik-email admin@example.com \
#     --traefik-hashed-password 'user:$$apr1$$...' \
#     --cf-dns-api-token xxxxxxxx \
#     --wp-db-root-password wp_root_pass \
#     --wp-db-password wp_user_pass
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, unset variable, or failed pipe

# Default values for variables
MYSQL_ROOT_PASSWORD=""
WORDPRESS_DB_PASSWORD=""
TRAEFIK_DOMAIN="example.com"
TRAEFIK_WILDCARD_DOMAIN="*.example.com"
TRAEFIK_EMAIL=""
TRAEFIK_HASHED_PASSWORD=""
CF_DNS_API_TOKEN=""
MARIA_DB_ROOT_PASSWORD=""
FRAPPE_ADMIN_PASSWORD=""
LETSENCRYPT_EMAIL=""
SITES=""
DOCKER_ACCOUNT=""
IMAGE_NAME=""
IMAGE_TAG=""
IS_LAN=false
COMPOSE_FILE="erpnext-one"

# Parse command line arguments for configuration
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mariadb-password)
            MARIA_DB_ROOT_PASSWORD="$2"  # Set MariaDB root password
            shift 2
            ;;
        --frappe-password)
            FRAPPE_ADMIN_PASSWORD="$2"   # Set Frappe admin password
            shift 2
            ;;
        --letsencrypt-email)
            LETSENCRYPT_EMAIL="$2"       # Set Let's Encrypt email
            shift 2
            ;;
        --sites)
            SITES="$2"                   # Set ERPNext sites (comma-separated)
            shift 2
            ;;
        --lan)
            COMPOSE_FILE="erpnext-one-lan"  # Use LAN compose file
            IS_LAN=true
            shift
            ;;
        --docker-account)
            DOCKER_ACCOUNT="$2"          # Set Docker Hub account
            shift 2
            ;;
        --image-name)
            IMAGE_NAME="$2"              # Set Docker image name
            shift 2
            ;;
        --image-tag)
            IMAGE_TAG="$2"               # Set Docker image tag
            shift 2
            ;;
        --traefik-domain)
            TRAEFIK_DOMAIN="$2"          # Set Traefik domain
            shift 2
            ;;
        --traefik-wildcard-domain)
            TRAEFIK_WILDCARD_DOMAIN="$2" # Set Traefik wildcard domain
            shift 2
            ;;
        --traefik-email)
            TRAEFIK_EMAIL="$2"           # Set Traefik email
            shift 2
            ;;
        --traefik-hashed-password)
            TRAEFIK_HASHED_PASSWORD="$2" # Set Traefik hashed password
            shift 2
            ;;
        --cf-dns-api-token)
            CF_DNS_API_TOKEN="$2"        # Set Cloudflare DNS API token
            shift 2
            ;;
        --wp-db-root-password)
            MYSQL_ROOT_PASSWORD="$2"     # Set WordPress DB root password
            shift 2
            ;;
        --wp-db-password)
            WORDPRESS_DB_PASSWORD="$2"   # Set WordPress DB user password
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --mariadb-password <password>    Set MariaDB root password"
            echo "  --frappe-password <password>     Set Frappe admin password"
            echo "  --letsencrypt-email <email>      Set email for Let's Encrypt"
            echo "  --sites <sites>                   Comma-separated list of ERPNext sites to create"
            echo "  --lan                             Enable LAN mode (uses erpnext-one-lan compose file)"
            echo "  --docker-account <account>        Docker Hub account name for images"
            echo "  --image-name <name>               Docker image name for ERPNext"
            echo "  --image-tag <tag>                 Docker image tag for ERPNext"
            echo "  --traefik-domain <domain>         Traefik domain"
            echo "  --traefik-wildcard-domain <domain> Traefik wildcard domain"
            echo "  --traefik-email <email>           Traefik email"
            echo "  --traefik-hashed-password <password> Traefik hashed password"
            echo "  --cf-dns-api-token <token>        Cloudflare DNS API token"
            echo "  --wp-db-root-password <password>  WordPress DB root password"
            echo "  --wp-db-password <password>       WordPress DB user password"
            echo "  --help, -h                        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Prompt for any required values not provided as arguments
if [[ -z "$MARIA_DB_ROOT_PASSWORD" ]]; then
    read -s -p "Enter MariaDB root password: " MARIA_DB_ROOT_PASSWORD
    echo
fi
if [[ -z "$FRAPPE_ADMIN_PASSWORD" ]]; then
    read -s -p "Enter Frappe admin password: " FRAPPE_ADMIN_PASSWORD
    echo
fi
if [[ -z "$LETSENCRYPT_EMAIL" ]]; then
    read -p "Enter Let's Encrypt email: " LETSENCRYPT_EMAIL
fi
if [[ -z "$SITES" ]]; then
    read -p "Enter comma-separated ERPNext sites to create: " SITES
fi
if [[ -z "$DOCKER_ACCOUNT" ]]; then
    read -p "Enter Docker account name: " DOCKER_ACCOUNT
fi
if [[ -z "$IMAGE_NAME" ]]; then
    read -p "Enter Docker image name for ERPNext: " IMAGE_NAME
fi
if [[ -z "$IMAGE_TAG" ]]; then
    read -p "Enter Docker image tag for ERPNext: " IMAGE_TAG
fi
if [[ -z "$TRAEFIK_DOMAIN" ]]; then
    read -p "Enter Traefik domain: " TRAEFIK_DOMAIN
fi
if [[ -z "$TRAEFIK_WILDCARD_DOMAIN" ]]; then
    read -p "Enter Traefik wildcard domain: " TRAEFIK_WILDCARD_DOMAIN
fi
if [[ -z "$TRAEFIK_EMAIL" ]]; then
    read -p "Enter Traefik email: " TRAEFIK_EMAIL
fi
if [[ -z "$TRAEFIK_HASHED_PASSWORD" ]]; then
    read -p "Enter Traefik hashed password: " TRAEFIK_HASHED_PASSWORD
fi
if [[ -z "$CF_DNS_API_TOKEN" ]]; then
    read -p "Enter Cloudflare DNS API token: " CF_DNS_API_TOKEN
fi
if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
    read -s -p "Enter WordPress DB root password: " MYSQL_ROOT_PASSWORD
    echo
fi
if [[ -z "$WORDPRESS_DB_PASSWORD" ]]; then
    read -s -p "Enter WordPress DB user password: " WORDPRESS_DB_PASSWORD
    echo
fi

# Ensure all ERPNext and Traefik scripts are executable
chmod +x erpnext/*.sh
chmod +x traefik/*.sh

# Start Traefik reverse proxy with the appropriate configuration
cd ./traefik
bash deploy_traefik.sh --lan="$IS_LAN" \
                       --domain "$TRAEFIK_DOMAIN" \
                       --wildcard-domain "$TRAEFIK_WILDCARD_DOMAIN" \
                       --email "$TRAEFIK_EMAIL" \
                       --hashed-password "$TRAEFIK_HASHED_PASSWORD" \
                       --cf-dns-api-token "$CF_DNS_API_TOKEN"

cd ..

# Start Portainer, WordPress, and Resume containers
for dir in ./portainer ./resume-gbacso; do
    # Check for docker-compose file in each directory
    if [ -f "$dir/docker-compose.yml" ] || [ -f "$dir/docker-compose.yaml" ]; then
        echo "Starting services in $dir..."
        (cd "$dir" && docker-compose up -d)  # Start containers in background
    else
        echo "No docker-compose file found in $dir, skipping."
    fi
done

# Start WordPress with the specified configuration
cd ./wordpress
docker-compose up -d \
    --build \
    --env MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    --env WORDPRESS_DB_PASSWORD="$WORDPRESS_DB_PASSWORD"

# Start ERPNext stack with the specified configuration
cd ./erpnext
bash deploy_erpnext.sh --db-password "$MARIA_DB_ROOT_PASSWORD" \
                        --letsencrypt-email "$LETSENCRYPT_EMAIL" \
                        --sites "$SITES" \
                        $([[ "$IS_LAN" == true ]] && echo "--lan") \
                        --docker-account "$DOCKER_ACCOUNT" \
                        --image-name "$IMAGE_NAME" \
                        --image-tag "$IMAGE_TAG"

echo "Starting services complete."  # All done!