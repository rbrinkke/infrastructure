#!/bin/bash

# install_ansible.sh
# Doel: Installeer Ansible via APT en configureer permissies voor swarm_user

set -e

# Update pakketlijst
sudo apt update

# Installeer prerequisites
sudo apt install -y software-properties-common

# Voeg Ansible PPA toe
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Installeer Ansible
sudo apt install -y ansible

# Verifieer installatie
ansible --version

# Controleer of swarm_user bestaat
if id "swarm_user" &>/dev/null; then
    echo "Gebruiker 'swarm_user' bestaat."
else
    echo "Gebruiker 'swarm_user' bestaat niet. Aanmaken..."
    sudo adduser --disabled-password --gecos '' swarm_user
fi

# Voeg swarm_user toe aan de groep rob
sudo usermod -aG rob swarm_user

# Installeer ACL indien nog niet geïnstalleerd
sudo apt install -y acl

# Stel permissies in voor Ansible directory
ANSIBLE_DIR="/home/rob/repos/infrastructure/ansible"

# Maak directory aan indien nodig
sudo mkdir -p $ANSIBLE_DIR

# Stel eigenaarschap en permissies in
sudo chown -R rob:rob $ANSIBLE_DIR
sudo chmod -R 750 $ANSIBLE_DIR

# Geef swarm_user toegang via ACL
sudo setfacl -m u:swarm_user:rx $ANSIBLE_DIR
sudo setfacl -R -m u:swarm_user:rx $ANSIBLE_DIR

# Voeg SSH-sleutel toe aan authorized_keys van swarm_user
AUTHORIZED_KEYS="/home/swarm_user/.ssh/authorized_keys"

# Maak .ssh directory aan indien nodig
sudo mkdir -p /home/swarm_user/.ssh

# Stel permissies in
sudo chmod 700 /home/swarm_user/.ssh

# Voeg public key toe
echo "Voeg de public key toe aan $AUTHORIZED_KEYS:"
read -p "Plak hier de public key: " PUBLIC_KEY
echo "$PUBLIC_KEY" | sudo tee -a $AUTHORIZED_KEYS

# Stel permissies in voor authorized_keys
sudo chmod 600 $AUTHORIZED_KEYS
sudo chown -R swarm_user:swarm_user /home/swarm_user/.ssh

echo "Ansible installatie en configuratie voltooid."

