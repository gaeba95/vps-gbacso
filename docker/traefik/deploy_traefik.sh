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

# Get command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lan)
            # Set the project name for LAN mode
            LAN_MODE=true
            shift
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

# Start Traefik with the specified Docker Compose files
docker compose --project-name traefik --env-file traefik.env $COMPOSE_FILES up -d