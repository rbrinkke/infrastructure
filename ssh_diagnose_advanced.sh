#!/bin/bash

TARGET_IP="172.29.109.21"
SSH_PORT="22"
SSH_USER="swarm_user"
SSH_KEY="/home/rob/.ssh/id_rsa"

echo "===== ADVANCED SSH NETWORK TEST SCRIPT ====="

# 1. Test of host al bereikbaar is via ping
echo "1. Controleer host bereikbaarheid..."
ping -c 1 "$TARGET_IP" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Host is bereikbaar (ping succesvol)."
else
    echo "   - ERROR: Host is niet bereikbaar. Sla verdere tests over."
    exit 1
fi
echo ""

# 2. Controleer of poort 22 open is
echo "2. Controleer poort $SSH_PORT..."
nc -zv "$TARGET_IP" "$SSH_PORT" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Poort $SSH_PORT is open op $TARGET_IP."
else
    echo "   - ERROR: Poort $SSH_PORT is niet bereikbaar. Controleer netwerk of firewallregels."
    exit 2
fi
echo ""

# 3. Controleer SSH-service op de server
echo "3. Controleer SSH-service status..."
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_IP" "echo 'SSH Connection Test Successful'" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - SSH-service is actief en toegankelijk voor gebruiker $SSH_USER."
else
    echo "   - ERROR: SSH-verbinding niet succesvol. Controleer logs op de server."
    echo "     Tip: Gebruik 'sudo tail -f /var/log/auth.log' op de server."
    exit 3
fi
echo ""

# 4. Controleer routing (wordt overgeslagen als ping en SSH succesvol waren)
if ! ip route get "$TARGET_IP" &> /dev/null; then
    echo "4. Controleer routing..."
    echo "   - ERROR: Routing naar $TARGET_IP lijkt incorrect. Controleer netwerkinstellingen."
    exit 4
else
    echo "   - Routing is correct. Host bereikbaar."
fi
echo ""

# 5. Verhoog tijdslimiet in GitHub Actions (indien nodig)
echo "5. Controleer GitHub Actions configuratie..."
if grep -q "timeout: " .github/workflows/*.yaml; then
    echo "   - Time-out instelling gevonden in GitHub Actions workflow."
else
    echo "   - ERROR: Geen time-out instelling gevonden. Voeg 'timeout: 120' toe in je GitHub Actions workflow."
    exit 5
fi
echo ""

echo "===== TEST COMPLETED ====="

