#!/bin/bash
# -----------------------------------------------------------------------------
# File: deploy_erpnext.sh
# Description: Automated deployment script for ERPNext using Docker Compose.
# Author: Gaetan Bacso
#
# Usage:
#   ./deploy_erpnext.sh [OPTIONS]
#
# Arguments:
#   --mariadb-password     MariaDB root password (prompted if not provided)
#   --frappe-password      Frappe admin password (prompted if not provided)
#   --letsencrypt-email    Email for Let's Encrypt (default: gaeba95@gmail.com)
#   --sites                Comma-separated list of site domains (default: erpnext.bacso.ch)
#   --lan                  Use LAN mode (changes compose file)
#   --docker-account       Docker Hub account (default: gaeba95)
#   --image-name           Docker image name (default: customappfrappe)
#   --image-tag            Docker image tag (default: latest)
# -----------------------------------------------------------------------------

MARIA_DB_ROOT_PASSWORD=""
FRAPPE_ADMIN_PASSWORD=""
LETSENCRYPT_EMAIL=""
SITES=""
DOCKER_ACCOUNT=""
IMAGE_NAME=""
IMAGE_TAG=""
IS_LAN=false
COMPOSE_FILE="erpnext-one"
# Parse command line options for passwords
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mariadb-password)
            MARIA_DB_ROOT_PASSWORD="$2"
            shift 2
            ;;
        --frappe-password)
            FRAPPE_ADMIN_PASSWORD="$2"
            shift 2
            ;;
        --letsencrypt-email)
            LETSENCRYPT_EMAIL="$2"
            shift 2
            ;;
        --sites)
            SITES="$2"
            shift 2
            ;;
        --lan)
            # Set the project name for LAN mode
            COMPOSE_FILE="erpnext-one-lan"
            IS_LAN=true
            shift
            ;;
        --docker-account)
            DOCKER_ACCOUNT="$2"
            shift 2
            ;;
        --image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --image-tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Prompt for passwords if not set
if [[ -z "$MARIA_DB_ROOT_PASSWORD" ]]; then
    read -s -p "Enter MariaDB root password: " MARIA_DB_ROOT_PASSWORD
    echo
fi

if [[ -z "$FRAPPE_ADMIN_PASSWORD" ]]; then
    read -s -p "Enter Frappe admin password: " FRAPPE_ADMIN_PASSWORD
    echo
fi

# Update CUSTOM_TAG if provided
if [[ -n "$MARIA_DB_ROOT_PASSWORD" ]]; then
    if grep -q '^DB_PASSWORD=' env/mariadb.env; then
        sed -i '' "s/^DB_PASSWORD=.*/DB_PASSWORD=`${MARIA_DB_ROOT_PASSWORD}`/" env/mariadb.env
    else
        echo "DB_PASSWORD=`${MARIA_DB_ROOT_PASSWORD}`" >> env/mariadb.env
    fi
fi

# Call the create_dockercompose_frappe script
bash create_dockercompose_frappe.sh --db-password "$MARIA_DB_ROOT_PASSWORD" \
                                    --letsencrypt-email "$LETSENCRYPT_EMAIL" \
                                    --sites "$SITES" \
                                    $([[ "$IS_LAN" == true ]] && echo "--lan") \
                                    --docker-account "$DOCKER_ACCOUNT" \
                                    --image-name "$IMAGE_NAME" \
                                    --image-tag "$IMAGE_TAG"

# Run mariadb container
docker compose --project-name mariadb --env-file env/mariadb.env -f frappe_docker/overrides/compose.mariadb-shared.yaml up -d

# Run erpnext-one container with the specified compose file
docker compose --project-name erpnext-one -f compose/${COMPOSE_FILE}.yaml up -d

# Wait for the MariaDB container to be ready
echo "Waiting for MariaDB to be ready..."
until docker compose --project-name mariadb exec mariadb mysqladmin ping -h localhost --silent; do
    sleep 1
done
echo "MariaDB is ready."
# Create sites
# Split the SITES variable into an array
IFS=',' read -ra SITE_ARRAY <<< "$SITES"
# Create sites using the bench command
for SITE in "${SITE_ARRAY[@]}"; do
    echo "Creating site: $SITE"
    # Ensure the site name is valid (no spaces, special characters, etc.)
    SITE=$(echo "$SITE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [[ -z "$SITE" ]]; then
        echo "Invalid site name: '$SITE'. Skipping."
        continue
    fi
    # Create the site using the bench command
    docker compose --project-name erpnext-one exec backend bench new-site "$SITE" --mariadb-user-host-login-scope='%' --mariadb-root-password "$MARIA_DB_ROOT_PASSWORD" --install-app erpnext --admin-password "$FRAPPE_ADMIN_PASSWORD"
    # Enable the scheduler for the site
    docker compose --project-name erpnext-one exec backend bench --site "$SITE" enable-scheduler
    # Install additional apps for the site
    for APP in hrms payments insights crm builder print_designer; do
        docker compose --project-name erpnext-one exec backend bench --site "$SITE" install-app "$APP"
    done
done