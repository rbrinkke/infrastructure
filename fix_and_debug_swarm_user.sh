#!/bin/bash

TARGET_IP="172.29.109.21"
SSH_USER="swarm_user"
SSH_KEY="/home/rob/.ssh/id_rsa"
SSH_DIR="/home/$SSH_USER/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
LOGFILE="/tmp/swarm_user_ssh_debug.log"

echo "===== Fix and Debug SSH for $SSH_USER =====" | tee -a $LOGFILE

# 1. Controleer of de gebruiker bestaat
echo "1. Controleer of gebruiker $SSH_USER bestaat..." | tee -a $LOGFILE
if id "$SSH_USER" &>/dev/null; then
    echo "   - Gebruiker $SSH_USER bestaat." | tee -a $LOGFILE
else
    echo "ERROR: Gebruiker $SSH_USER bestaat niet." | tee -a $LOGFILE
    exit 1
fi
echo ""

# 2. Herstel permissies voor .ssh en authorized_keys
echo "2. Herstel permissies voor $SSH_DIR en $AUTHORIZED_KEYS..." | tee -a $LOGFILE
sudo mkdir -p "$SSH_DIR"
sudo chmod 700 "$SSH_DIR"
sudo chown "$SSH_USER:$SSH_USER" "$SSH_DIR"
sudo cp "$SSH_KEY.pub" "$AUTHORIZED_KEYS"
sudo chmod 600 "$AUTHORIZED_KEYS"
sudo chown "$SSH_USER:$SSH_USER" "$AUTHORIZED_KEYS"
echo "   - Permissies hersteld." | tee -a $LOGFILE
echo ""

# 3. Controleer SSH-configuratie
echo "3. Controleer en herstel SSH-configuratie..." | tee -a $LOGFILE
SSHD_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONFIG" ]; then
    sudo sed -i '/^AllowUsers/d' "$SSHD_CONFIG"
    echo "AllowUsers rob $SSH_USER" | sudo tee -a "$SSHD_CONFIG" &>/dev/null
    sudo sed -i '/^PubkeyAuthentication/d' "$SSHD_CONFIG"
    echo "PubkeyAuthentication yes" | sudo tee -a "$SSHD_CONFIG" &>/dev/null
    echo "   - SSH-configuratie aangepast." | tee -a $LOGFILE
    sudo systemctl restart ssh
    echo "   - SSH-service herstart." | tee -a $LOGFILE
else
    echo "ERROR: $SSHD_CONFIG niet gevonden." | tee -a $LOGFILE
    exit 2
fi
echo ""

# 4. Test verbinding met SSH
echo "4. Test SSH-verbinding..." | tee -a $LOGFILE
ssh -i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_IP" "echo Connection successful" &>> $LOGFILE
if [ $? -eq 0 ]; then
    echo "   - SSH-verbinding succesvol." | tee -a $LOGFILE
else
    echo "ERROR: SSH-verbinding mislukt. Controleer logs." | tee -a $LOGFILE
    ssh rob@$TARGET_IP "sudo tail -n 20 /var/log/auth.log" &>> $LOGFILE
    exit 3
fi
echo ""

echo "===== Fix and Debug Completed =====" | tee -a $LOGFILE
echo "Bekijk logbestand voor details: $LOGFILE"

