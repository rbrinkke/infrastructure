#!/bin/bash

# Variabelen
TARGET_IP="172.29.109.21"
SSH_PORT="22"

echo "===== SSH CONNECTIVITY TEST ====="

# 1. Test bereikbaarheid met ping
echo "1. Test bereikbaarheid via ping..."
ping -c 4 "$TARGET_IP" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Ping succesvol: $TARGET_IP is bereikbaar."
else
    echo "   - ERROR: Geen ping-respons van $TARGET_IP."
    exit 1
fi
echo ""

# 2. Test poorttoegang met nc
echo "2. Test toegang tot poort $SSH_PORT..."
nc -zv "$TARGET_IP" "$SSH_PORT" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Poort $SSH_PORT is open op $TARGET_IP."
else
    echo "   - ERROR: Poort $SSH_PORT is niet bereikbaar op $TARGET_IP."
    exit 2
fi
echo ""

# 3. Controleer SSH-service (alleen op lokale machine)
if [ "$TARGET_IP" == "127.0.0.1" ] || [ "$TARGET_IP" == "$(hostname -I | awk '{print $1}')" ]; then
    echo "3. Controleer SSH-service lokaal..."
    sudo systemctl status ssh | grep "Active: active (running)" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "   - SSH-service draait op de lokale machine."
    else
        echo "   - ERROR: SSH-service is niet actief op de lokale machine."
        exit 3
    fi
    echo ""
else
    echo "3. SSH-service controle wordt overgeslagen (niet lokaal)."
    echo ""
fi

# 4. Test handmatige SSH-verbinding
echo "4. Test SSH-verbinding..."
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USER@$TARGET_IP" "echo Connection successful" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - SSH-verbinding succesvol naar $TARGET_IP."
else
    echo "   - ERROR: SSH-verbinding mislukt naar $TARGET_IP."
    exit 4
fi

echo "===== TEST VOLTOOID ====="

