#!/bin/bash

# Variabelen (pas aan naar jouw situatie)
REMOTE_USER="swarm_user"
REMOTE_HOST="192.168.178.183"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"

echo "=== SSH Debugging Test Script ==="

# Stap 1: Controleer of het bestand bestaat
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "[ERROR] Private key not found at $SSH_KEY_PATH"
  exit 1
fi
echo "[OK] Private key found."

# Stap 2: Controleer permissies
PERM=$(stat -c "%a" "$SSH_KEY_PATH")
if [ "$PERM" != "600" ]; then
  echo "[WARNING] Permissions for private key are $PERM. Fixing..."
  chmod 600 "$SSH_KEY_PATH"
  echo "[OK] Permissions set to 600."
else
  echo "[OK] Private key permissions are correct."
fi

# Stap 3: Controleer netwerktoegang
echo "[INFO] Testing network connectivity..."
ping -c 1 "$REMOTE_HOST" &>/dev/null
if [ $? -ne 0 ]; then
  echo "[ERROR] Cannot reach $REMOTE_HOST. Check network or firewall."
  exit 1
fi
echo "[OK] Network connectivity to $REMOTE_HOST is fine."

# Stap 4: Controleer of SSH-poort open is
echo "[INFO] Checking SSH port..."
nc -zv "$REMOTE_HOST" 22 &>/dev/null
if [ $? -ne 0 ]; then
  echo "[ERROR] SSH port 22 is not open. Check server firewall."
  exit 1
fi
echo "[OK] SSH port 22 is open."

# Stap 5: Probeer SSH-verbinding
echo "[INFO] Attempting SSH connection..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH" "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH connection successful!'" 2>&1 | tee ssh_debug.log

# Controleer output van SSH-verbinding
if grep -q "Permission denied" ssh_debug.log; then
  echo "[ERROR] Permission denied. Check authorized_keys on the server."
elif grep -q "Connection timed out" ssh_debug.log; then
  echo "[ERROR] Connection timed out. Check network/firewall."
elif grep -q "SSH connection successful" ssh_debug.log; then
  echo "[SUCCESS] SSH connection established successfully!"
else
  echo "[ERROR] Unknown issue. See ssh_debug.log for details."
fi

# Cleanup
rm -f ssh_debug.log

echo "=== SSH Debugging Test Complete ==="

