#!/bin/bash
# -----------------------------------------------------------------------------
# File: install_server.sh
# Description: Installs Docker Engine, CLI, and dependencies on Ubuntu server.
# Author: Gaetan Bacso
# Usage: bash install_server.sh
# -----------------------------------------------------------------------------

set -euo pipefail

echo "Starting server installation..."

# Update package list and install prerequisites
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Install Docker repository
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# Install Docker Engine, CLI, and containerd
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to the docker group
sudo usermod -aG docker ${USER}

echo "Server installation complete."