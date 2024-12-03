#!/bin/bash

TARGET_IP="172.29.109.21"
SSH_PORT="22"

echo "===== SSH NETWORK TEST SCRIPT ====="

# 1. Test bereikbaarheid van de host
echo "1. Test bereikbaarheid van de host ($TARGET_IP)..."
ping -c 4 "$TARGET_IP" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Host is bereikbaar (ping succesvol)."
else
    echo "   - ERROR: Host is niet bereikbaar (ping mislukt). Controleer netwerkverbinding of serverstatus."
    exit 1
fi
echo ""

# 2. Test toegang tot poort 22
echo "2. Test toegang tot poort $SSH_PORT..."
nc -zv "$TARGET_IP" "$SSH_PORT" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Poort $SSH_PORT is open op $TARGET_IP."
else
    echo "   - ERROR: Poort $SSH_PORT is niet bereikbaar. Controleer firewallinstellingen of beveiligingsgroepen."
    exit 2
fi
echo ""

# 3. Controleer firewallregels (indien lokaal)
echo "3. Controleer firewallregels (indien lokaal)..."
if [ "$TARGET_IP" == "127.0.0.1" ] || [ "$TARGET_IP" == "$(hostname -I | awk '{print $1}')" ]; then
    sudo ufw status | grep -qw "22/tcp"
    if [ $? -eq 0 ]; then
        echo "   - Poort 22 is toegestaan in de firewall."
    else
        echo "   - ERROR: Poort 22 is geblokkeerd door de firewall. Voeg een regel toe:"
        echo "     sudo ufw allow 22"
        exit 3
    fi
else
    echo "   - Firewallcontrole wordt overgeslagen (host is niet lokaal)."
fi
echo ""

# 4. Test SSH-service op de server
echo "4. Controleer SSH-service op de server..."
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no rob@"$TARGET_IP" "echo 'SSH Connection Test Successful'" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - SSH-service is actief en bereikbaar."
else
    echo "   - ERROR: SSH-service is niet bereikbaar of weigert verbindingen. Controleer logs op de server."
    echo "     Log in op de server en controleer met:"
    echo "     sudo systemctl status ssh"
    echo "     sudo tail -f /var/log/auth.log"
    exit 4
fi
echo ""

# 5. Controleer routing en netwerk
echo "5. Controleer routing en netwerkconnectiviteit..."
ip route get "$TARGET_IP" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - Routing naar $TARGET_IP is correct ingesteld."
else
    echo "   - ERROR: Routing naar $TARGET_IP is niet correct. Controleer routeringsinstellingen en netwerkconfiguratie."
    exit 5
fi
echo ""

echo "===== TEST COMPLETED ====="

