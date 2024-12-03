#!/bin/bash

# Variabelen
TARGET_IP="172.29.109.21"
SSH_PORT="22"
SSH_USER="swarm_user"
SSH_KEY="$HOME/.ssh/id_rsa" # Standaard SSH-sleutel

echo "===== SSH DIAGNOSE SCRIPT (swarm_user) ====="

# 1. Test bereikbaarheid via ping
echo "1. Test bereikbaarheid via ping..."
ping -c 4 "$TARGET_IP" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Ping succesvol: $TARGET_IP is bereikbaar."
else
    echo "   - ERROR: Geen ping-respons van $TARGET_IP."
    exit 1
fi
echo ""

# 2. Test toegang tot poort 22
echo "2. Test toegang tot poort $SSH_PORT..."
nc -zv "$TARGET_IP" "$SSH_PORT" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Poort $SSH_PORT is open op $TARGET_IP."
else
    echo "   - ERROR: Poort $SSH_PORT is niet bereikbaar op $TARGET_IP."
    exit 2
fi
echo ""

# 3. Test verbinding met gebruiker swarm_user
echo "3. Test SSH-verbinding met gebruiker ($SSH_USER)..."
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_IP" "echo Connection successful" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - SSH-verbinding succesvol met gebruiker $SSH_USER."
else
    echo "   - ERROR: SSH-verbinding mislukt met gebruiker $SSH_USER."
    exit 3
fi
echo ""

# 4. Test verbinding met sleutel
echo "4. Test SSH-verbinding met sleutel ($SSH_KEY)..."
if [ -f "$SSH_KEY" ]; then
    ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_IP" "echo Connection successful" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "   - SSH-verbinding succesvol met sleutel."
    else
        echo "   - ERROR: SSH-verbinding mislukt met sleutel $SSH_KEY."
        exit 4
    fi
else
    echo "   - ERROR: Sleutelbestand niet gevonden ($SSH_KEY). Controleer het pad."
    exit 4
fi
echo ""

echo "===== DIAGNOSE VOLTOOID ====="

