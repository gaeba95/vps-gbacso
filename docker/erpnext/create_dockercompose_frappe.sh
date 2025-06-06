#!/bin/bash
# -----------------------------------------------------------------------------
# File: create_dockercompose_frappe.sh
# Description: Creates a Docker Compose file for the Frappe Docker project.
#              Handles environment variable updates and argument parsing.
# Author: Gaetan Bacso
#
# Usage:
#   ./create_dockercompose_frappe.sh [OPTIONS]
#
# Arguments:
#   --db-password <password>        Set the database password (required)
#   --letsencrypt-email <email>     Set the Let's Encrypt email (required)
#   --sites <sites>                 Set the sites variable (required)
#   --lan                           Use LAN mode (changes compose file names)
#   --docker-account <account>      Set the Docker account for custom image
#   --image-name <name>             Set the Docker image name
#   --image-tag <tag>               Set the Docker image tag
# -----------------------------------------------------------------------------

# Set the default values for the variables
COMPOSE_NAME="erpnext-one.yaml"
COMPOSE_ARCH="compose.yaml"
DB_PASSWORD=""
LETSENCRYPT_EMAIL=""
SITES=""
DOCKER_ACCOUNT=""
IMAGE_NAME=""
IMAGE_TAG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --db-password)
            DB_PASSWORD="$2"
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
            COMPOSE_NAME="erpnext-one-lan.yaml"
            COMPOSE_ARCH="compose_arm64.yaml"
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
            shift
            ;;
    esac
done

# Prompt for DB_PASSWORD if not provided
if [[ -z "$DB_PASSWORD" ]]; then
    read -s -p "Enter DB password: " DB_PASSWORD
    echo
fi

if [[ -z "$DB_PASSWORD" ]]; then
    echo "DB password is required."
    exit 1
fi

if [[ -z "$LETSENCRYPT_EMAIL" ]]; then
    echo "LETSENCRYPT_EMAIL is required."
    exit 1
fi

if [[ -z "$SITES" ]]; then
    echo "SITES is required."
    exit 1
fi

# Check if the required directories exist
if [[ ! -d "frappe_docker" ]]; then
    echo "Directory 'frappe_docker' does not exist. Please run this script from the correct directory."
    exit 1
fi

# Change to the frappe_docker directory
cd frappe_docker

# Update DB_PASSWORD in ../env/erpnext-one.env
if grep -q '^DB_PASSWORD=' ../env/erpnext-one.env; then
    sed -i '' "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" ../env/erpnext-one.env
else
    echo "DB_PASSWORD=${DB_PASSWORD}" >> ../env/erpnext-one.env
fi

# Update LETSENCRYPT_EMAIL if provided
if [[ -n "$LETSENCRYPT_EMAIL" ]]; then
    if grep -q '^LETSENCRYPT_EMAIL=' ../env/erpnext-one.env; then
        sed -i '' "s/^LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}/" ../env/erpnext-one.env
    else
        echo "LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}" >> ../env/erpnext-one.env
    fi
fi

# Update SITES if provided
if [[ -n "$SITES" ]]; then
    if grep -q '^SITES=' ../env/erpnext-one.env; then
        sed -i '' "s/^SITES=.*/SITES=`${SITES}`/" ../env/erpnext-one.env
    else
        echo "SITES=`${SITES}`" >> ../env/erpnext-one.env
    fi
fi

CUSTOM_IMAGE="$DOCKER_ACCOUNT/$IMAGE_NAME"

# Update CUSTOM_IMAGE if provided
if [[ -n "$CUSTOM_IMAGE" ]]; then
    if grep -q '^CUSTOM_IMAGE=' ../env/erpnext-one.env; then
        sed -i '' "s/^CUSTOM_IMAGE=.*/CUSTOM_IMAGE=`${CUSTOM_IMAGE}`/" ../env/erpnext-one.env
    else
        echo "CUSTOM_IMAGE=`${CUSTOM_IMAGE}`" >> ../env/erpnext-one.env
    fi
fi

# Update CUSTOM_TAG if provided
if [[ -n "$IMAGE_TAG" ]]; then
    if grep -q '^CUSTOM_TAG=' ../env/erpnext-one.env; then
        sed -i '' "s/^CUSTOM_TAG=.*/CUSTOM_TAG=`${IMAGE_TAG}`/" ../env/erpnext-one.env
    else
        echo "CUSTOM_TAG=`${IMAGE_TAG}`" >> ../env/erpnext-one.env
    fi
fi

docker compose --project-name erpnext-one --env-file ../env/erpnext-one.env -f ../compose/${COMPOSE_ARCH} -f overrides/compose.redis.yaml -f overrides/compose.multi-bench.yaml config > ../compose/${COMPOSE_NAME}