#!/bin/bash

# Configuratievariabelen
EMAIL="robbrinkkemper@gmail.com"  # Vul jouw e-mailadres in
SERVER_USER="swarm_user"          # De gebruiker op de server
SERVER_IP="172.29.109.21"         # Gevonden IP-adres

# Controleer of de server bereikbaar is
echo "Controleren of $SERVER_IP bereikbaar is..."
ping -c 1 $SERVER_IP > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Fout: Server $SERVER_IP is niet bereikbaar. Controleer je netwerkconfiguratie."
  exit 1
fi

# Genereer SSH-sleutels
echo "SSH-sleutel genereren voor $EMAIL..."
ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f ~/.ssh/id_rsa -N ""

# Voeg publieke sleutel toe aan de server
echo "Publieke sleutel toevoegen aan de server..."
ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo \"$(cat ~/.ssh/id_rsa.pub)\" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Test de verbinding
echo "Verbinding testen..."
ssh -i ~/.ssh/id_rsa "$SERVER_USER@$SERVER_IP" echo "SSH-toegang succesvol ingesteld!"

echo "Alles is klaar! Je kunt nu verbinden met: ssh -i ~/.ssh/id_rsa $SERVER_USER@$SERVER_IP"
