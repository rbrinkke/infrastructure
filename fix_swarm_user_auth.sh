#!/bin/bash

TARGET_IP="172.29.109.21"
SSH_USER="swarm_user"
SSH_KEY="/home/swarm_user/.ssh/id_ed25519.pub"
AUTHORIZED_KEYS="/home/swarm_user/.ssh/authorized_keys"
LOGFILE="/home/rob/fix_swarm_user_auth.log"

echo "===== Fix SSH Authentication for $SSH_USER =====" | tee -a $LOGFILE

# 1. Controleer of .ssh-directory bestaat
echo "1. Controleer en herstel .ssh-directory..." | tee -a $LOGFILE
sudo mkdir -p /home/$SSH_USER/.ssh
sudo chmod 700 /home/$SSH_USER/.ssh
sudo chown $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh
echo "   - .ssh-directory is correct ingesteld." | tee -a $LOGFILE

# 2. Controleer en herstel authorized_keys
echo "2. Controleer en herstel authorized_keys..." | tee -a $LOGFILE
if [ ! -f "$AUTHORIZED_KEYS" ]; then
    sudo touch "$AUTHORIZED_KEYS"
    sudo chmod 600 "$AUTHORIZED_KEYS"
    sudo chown $SSH_USER:$SSH_USER "$AUTHORIZED_KEYS"
    echo "   - authorized_keys bestand aangemaakt." | tee -a $LOGFILE
fi

# Voeg publieke sleutel toe aan authorized_keys
PUB_KEY="/home/rob/.ssh/id_ed25519.pub"
if [ -f "$PUB_KEY" ]; then
    sudo cat "$PUB_KEY" | sudo tee -a "$AUTHORIZED_KEYS" &>/dev/null
    echo "   - Publieke sleutel toegevoegd aan authorized_keys." | tee -a $LOGFILE
else
    echo "   - ERROR: Publieke sleutel niet gevonden ($PUB_KEY)." | tee -a $LOGFILE
    exit 1
fi

# 3. Controleer SSH-configuratie
echo "3. Controleer en herstel SSH-configuratie..." | tee -a $LOGFILE
SSHD_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONFIG" ]; then
    sudo sed -i '/^AllowUsers/d' "$SSHD_CONFIG"
    echo "AllowUsers rob $SSH_USER" | sudo tee -a "$SSHD_CONFIG" &>/dev/null
    echo "   - swarm_user toegevoegd aan AllowUsers." | tee -a $LOGFILE
else
    echo "   - ERROR: SSH-configuratiebestand niet gevonden." | tee -a $LOGFILE
    exit 2
fi

# Herstart SSH-service
sudo systemctl restart ssh
echo "   - SSH-service herstart." | tee -a $LOGFILE

# 4. Test verbinding met SSH
echo "4. Test SSH-verbinding met $SSH_USER..." | tee -a $LOGFILE
timeout 5 ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_IP" "echo 'SSH test successful'" &>> $LOGFILE
if [ $? -eq 0 ]; then
    echo "   - SSH-verbinding succesvol." | tee -a $LOGFILE
else
    echo "   - ERROR: SSH-verbinding mislukt. Controleer logs." | tee -a $LOGFILE
    exit 3
fi

echo "===== Fix SSH Authentication Completed =====" | tee -a $LOGFILE
