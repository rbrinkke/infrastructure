#!/usr/bin/env bash

# Containernaam die NIET verwijderd moet worden
EXCLUDE_CONTAINER="vault-permanent"

echo "Zoeken naar containers die gestopt en verwijderd moeten worden (behalve $EXCLUDE_CONTAINER)..."

# Haal alle container-ID's op behalve de uitgesloten container
containers_to_remove=$(docker ps -a --format '{{.ID}} {{.Names}}' | grep -v "$EXCLUDE_CONTAINER" | awk '{print $1}')

if [ -z "$containers_to_remove" ]; then
    echo "Geen containers gevonden om te stoppen en te verwijderen."
    exit 0
fi

echo "Containers die worden gestopt en verwijderd:"
docker ps -a --format '{{.ID}} {{.Names}}' | grep -v "$EXCLUDE_CONTAINER"

# Stop en verwijder alle geselecteerde containers
for container_id in $containers_to_remove; do
    echo "Stoppen van container $container_id..."
    docker stop "$container_id"
    echo "Verwijderen van container $container_id..."
    docker rm "$container_id"
done

echo "Alle containers behalve $EXCLUDE_CONTAINER zijn gestopt en verwijderd."

