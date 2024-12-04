#!/bin/bash

# Instellingen
SWARM_HOST_IP="192.168.178.183" # IP-adres van de host
SSH_USER="swarm_user"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"

# Controleer of de SSH-sleutel bestaat
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "Error: SSH-sleutel niet gevonden op $SSH_KEY_PATH."
    exit 1
fi

# Controleer de connectiviteit naar het IP-adres
echo "Controleer connectiviteit naar $SWARM_HOST_IP..."
if ping -c 3 "$SWARM_HOST_IP" > /dev/null 2>&1; then
    echo "Ping succesvol. Host is bereikbaar."
else
    echo "Error: Host $SWARM_HOST_IP is niet bereikbaar."
    exit 1
fi

# Controleer of poort 22 open is
echo "Controleer of poort 22 open is op $SWARM_HOST_IP..."
if nc -zv "$SWARM_HOST_IP" 22 > /dev/null 2>&1; then
    echo "Poort 22 is open. SSH kan worden geprobeerd."
else
    echo "Error: Poort 22 is niet open op $SWARM_HOST_IP."
    exit 1
fi

# Test SSH-verbinding
echo "Test SSH-verbinding naar $SSH_USER@$SWARM_HOST_IP..."
if ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$SSH_USER@$SWARM_HOST_IP" "echo 'SSH verbinding succesvol'" > /dev/null 2>&1; then
    echo "SSH verbinding succesvol."
else
    echo "Error: SSH verbinding mislukt. Controleer sleutel en toegangsrechten."
    exit 1
fi

echo "Alle controles succesvol. SSH verbinding is correct ingesteld."

