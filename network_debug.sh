#!/bin/bash

TARGET_IP="172.29.109.21"
SSH_PORT="22"
LOGFILE="/home/swarm_user/network_debug.log" # Logbestand in de home-directory van swarm_user

echo "===== NETWORK DEBUG SCRIPT =====" | tee -a $LOGFILE

# 1. Controleer bereikbaarheid van host
echo "1. Test bereikbaarheid van host ($TARGET_IP)..." | tee -a $LOGFILE
ping -c 4 "$TARGET_IP" &>> $LOGFILE
if [ $? -eq 0 ]; then
    echo "   - Host is bereikbaar (ping succesvol)." | tee -a $LOGFILE
else
    echo "   - ERROR: Host is niet bereikbaar (ping mislukt)." | tee -a $LOGFILE
    exit 1
fi
echo ""

# 2. Test poorttoegang met nc
echo "2. Test toegang tot poort $SSH_PORT..." | tee -a $LOGFILE
nc -zv "$TARGET_IP" "$SSH_PORT" &>> $LOGFILE
if [ $? -eq 0 ]; then
    echo "   - Poort $SSH_PORT is open op $TARGET_IP." | tee -a $LOGFILE
else
    echo "   - ERROR: Poort $SSH_PORT is niet bereikbaar." | tee -a $LOGFILE
    echo "     Controleer of de firewall of netwerkregels toegang blokkeren." | tee -a $LOGFILE
    exit 2
fi
echo ""

# 3. Controleer routeringsproblemen
echo "3. Controleer routing naar $TARGET_IP..." | tee -a $LOGFILE
ip route get "$TARGET_IP" &>> $LOGFILE
if [ $? -eq 0 ]; then
    echo "   - Routing naar $TARGET_IP is correct." | tee -a $LOGFILE
else
    echo "   - ERROR: Routing naar $TARGET_IP is niet correct. Controleer routeringsregels." | tee -a $LOGFILE
    exit 3
fi
echo ""

# 4. Test of SSH-service reageert
echo "4. Test reactie van SSH-service..." | tee -a $LOGFILE
timeout 5 ssh -o BatchMode=yes -o StrictHostKeyChecking=no "rob@$TARGET_IP" "echo 'SSH test successful'" &>> $LOGFILE
if [ $? -eq 0 ]; then
    echo "   - SSH-service reageert correct." | tee -a $LOGFILE
else
    echo "   - ERROR: SSH-service reageert niet. Controleer serverlogs." | tee -a $LOGFILE
    exit 4
fi
echo ""

echo "===== NETWORK DEBUG COMPLETED =====" | tee -a $LOGFILE
echo "Bekijk logbestand voor details: $LOGFILE"

