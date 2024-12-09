#!/usr/bin/env bash

CONTAINER_ID="369924f9bb05"

while true; do
    # Haal de health status op via docker inspect
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_ID")

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        echo "De Vault container is nu healthy!"
        break
    else
        echo "Vault container is nog niet gezond (status: $HEALTH_STATUS). Nog even wachten..."
        sleep 10
    fi
done

