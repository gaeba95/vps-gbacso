#!/bin/bash
# -----------------------------------------------------------------------------
# File: builds_apps_docker_image.sh
# Description: Build and push a custom ERPNext Docker image with selected apps.
# Author: Gaetan Bacso
#
# Usage:
#   ./builds_apps_docker_image.sh [--docker-account <account>] [--image-name <name>] [--image-tag <tag>] [--platform <platforms>]
#
# Arguments:
#   --docker-account   Docker Hub account to use (default: gaeba95)
#   --image-name       Name of the Docker image (default: customappfrappe)
#   --image-tag        Tag for the Docker image (default: latest)
#   --platform         Target platforms for the build (default: linux/amd64,linux/arm64)
# -----------------------------------------------------------------------------

# Default values
DOCKER_ACCOUNT="gaeba95"
IMAGE_NAME="customappfrappe"
IMAGE_TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case $1 in
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
    --platform)
      PLATFORMS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Define a JSON array of app repositories and branches to include in the build
export APPS_JSON='[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/payments",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/crm",
    "branch": "v1.46.2"
  },
  {
    "url": "https://github.com/frappe/insights",
    "branch": "version-3"
  },
  {
    "url": "https://github.com/frappe/print_designer",
    "branch": "v1.5.2"
  },
  {
    "url": "https://github.com/frappe/builder",
    "branch": "v1.17.0"
  }
]'

# Convert the JSON array to a base64 encoded string for use in the Docker build
export APPS_JSON_BASE64=$(echo ${APPS_JSON} | base64 -w 0)

# Ensure the script is run from the frappe_docker directory
git clone https://github.com/frappe/frappe_docker
cd frappe_docker

# Ensure Docker Buildx is set up
if ! docker buildx inspect mybuilder &>/dev/null; then
  docker buildx create --name mybuilder --use
fi
# Ensure the builder is ready
docker buildx inspect mybuilder --bootstrap
# Log in to Docker Hub (or your registry) before building the image
docker login
if ! docker login --username=${DOCKER_ACCOUNT}; then
  echo "Docker login failed. Please check your credentials."
  exit 1
fi
# Build and push the Docker image with the specified platforms and apps
docker buildx build \
  --platform $PLATFORMS \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-15 \
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag=$DOCKER_ACCOUNT/$IMAGE_NAME:$IMAGE_TAG \
  --file=images/layered/Containerfile \
  --push .
