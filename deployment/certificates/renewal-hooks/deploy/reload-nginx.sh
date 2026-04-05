#!/bin/bash

set -e

DOCKER_COMPOSE_PATH="/home/ubuntu/geneweb/deployment"
NGINX_CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep nginx)

cd "$DOCKER_COMPOSE_PATH"

if docker exec "$NGINX_CONTAINER_NAME" nginx -s reload 2> /dev/null; then
    echo "Successfully reloaded nginx"
    exit 0
else
    echo "Unable to reload nginx"
    exit 1
fi