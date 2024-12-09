#!/bin/bash

# Controleer of Docker is geïnstalleerd
if ! command -v docker &> /dev/null
then
    echo "Docker is niet geïnstalleerd. Installeer Docker voordat je dit script uitvoert."
    exit 1
fi

# Stop alle draaiende containers
echo "Bezig met stoppen van alle draaiende Docker-containers..."
RUNNING_CONTAINERS=$(docker ps -q)

if [ -n "$RUNNING_CONTAINERS" ]; then
    docker stop $RUNNING_CONTAINERS
    echo "Alle draaiende containers zijn gestopt."
else
    echo "Er zijn geen draaiende containers om te stoppen."
fi

# Verwijder alle containers (zowel draaiend als gestoppt)
echo "Bezig met verwijderen van alle Docker-containers..."
ALL_CONTAINERS=$(docker ps -a -q)

if [ -n "$ALL_CONTAINERS" ]; then
    docker rm $ALL_CONTAINERS
    echo "Alle containers zijn verwijderd."
else
    echo "Er zijn geen containers om te verwijderen."
fi

echo "Docker purge is voltooid."

