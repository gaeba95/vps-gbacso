#!/bin/bash
#===============================================================================
# File: deploy_traefik.sh
# Description: Deploys Traefik using Docker Compose with optional LAN mode.
# Author: Gaetan Bacso
#
# Usage: ./deploy_traefik.sh [--lan]
#
# Arguments:
#   --lan    Use the LAN-specific Docker Compose configuration.
#===============================================================================

# Set variables
LAN_MODE=false
TRAEFIK_DOMAIN="example.com"
TRAEFIK_WILDCARD_DOMAIN="*.example.com"
EMAIL=""
HASHED_PASSWORD=""
CF_DNS_API_TOKEN=""

# Get command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lan)
            # Set the project name for LAN mode
            LAN_MODE=true
            shift
            ;;
        --domain)
            TRAEFIK_DOMAIN="$2"
            shift 2
            ;;
        --wildcard-domain)
            TRAEFIK_WILDCARD_DOMAIN="$2"
            shift 2
            ;;
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --hashed-password)
            HASHED_PASSWORD="$2"
            shift 2
            ;;
        --cf-dns-api-token)
            CF_DNS_API_TOKEN="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Set the Docker Compose files based on LAN mode
COMPOSE_FILES="-f compose.traefik.yaml"
if [ "$LAN_MODE" = false ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f compose.traefik-ssl.yaml"
fi

# Create the environment file for Traefik
cat > traefik.env <<EOF
TRAEFIK_DOMAIN=$TRAEFIK_DOMAIN
TRAEFIK_WILDCARD_DOMAIN=$TRAEFIK_WILDCARD_DOMAIN
EMAIL=$EMAIL
HASHED_PASSWORD=$HASHED_PASSWORD
CF_DNS_API_TOKEN=$CF_DNS_API_TOKEN
TRAEFIK_LAN_MODE=$LAN_MODE
# Additional environment variables can be added here
# For example, if you need to set a specific network or other configurations
# TRAEFIK_NETWORK=traefik_network
# TRAEFIK_LOG_LEVEL=DEBUG
# TRAEFIK_API_INSECURE=true
# TRAEFIK_ENTRYPOINTS_HTTP_ADDRESS=:80
# TRAEFIK_ENTRYPOINTS_HTTPS_ADDRESS=:443
EOF

# Start Traefik with the specified Docker Compose files
docker compose --project-name traefik --env-file traefik.env $COMPOSE_FILES up -d