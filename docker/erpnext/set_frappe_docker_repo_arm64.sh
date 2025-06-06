#!/bin/bash
cd frappe_docker
docker buildx bake --no-cache --set "*.platform=linux/arm64"
