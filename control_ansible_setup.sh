#!/bin/bash

# control_ansible_setup.sh
# Doel: Installeer Ansible via APT, update de repository, en configureer permissies voor swarm_user

set -e

# Variabelen
REPO_DIR="/home/rob/repos/infrastructure"
GITHUB_REPO="https://github.com/rbrinkke/infrastructure.git"
SWARM_USER="swarm_user"
ANSIBLE_DIR="$REPO_DIR/ansible"
AUTHORIZED_KEYS="/home/$SWARM_USER/.ssh/authorized_keys"

# Update pakketlijst en installeer prerequisites
sudo apt update
sudo apt install -y software-properties-common acl git

# Voeg Ansible PPA toe en installeer Ansible
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Verifieer Ansible installatie
ansible-playbook --version

# Controleer of swarm_user bestaat, zo niet, maak aan
if id "$SWARM_USER" &>/dev/null; then
    echo "Gebruiker '$SWARM_USER' bestaat."
else
    echo "Gebruiker '$SWARM_USER' bestaat niet. Aanmaken..."
    sudo adduser --disabled-password --gecos '' "$SWARM_USER"
fi

# Voeg swarm_user toe aan de groep rob
sudo usermod -aG rob "$SWARM_USER"

# Clone of update de repository
if [ -d "$REPO_DIR/.git" ]; then
    echo "Repository bestaat. Pull laatste wijzigingen."
    sudo -u rob git -C "$REPO_DIR" pull
else
    echo "Repository bestaat niet. Clonen..."
    sudo -u rob git clone "$GITHUB_REPO" "$REPO_DIR"
fi

# Stel eigenaarschap en permissies in
sudo chown -R rob:rob "$REPO_DIR"
sudo chmod -R 750 "$REPO_DIR"

# Geef swarm_user toegang via ACL
sudo setfacl -m u:"$SWARM_USER":rx "$ANSIBLE_DIR"
sudo setfacl -R -m u:"$SWARM_USER":rx "$ANSIBLE_DIR"

# Stel SSH in voor swarm_user
sudo mkdir -p /home/"$SWARM_USER"/.ssh
sudo chmod 700 /home/"$SWARM_USER"/.ssh

# Voeg public key toe
echo "Voeg de public key toe aan $AUTHORIZED_KEYS:"
read -p "Plak hier de public key: " PUBLIC_KEY
echo "$PUBLIC_KEY" | sudo tee -a "$AUTHORIZED_KEYS"

# Stel permissies in voor authorized_keys
sudo chmod 600 "$AUTHORIZED_KEYS"
sudo chown -R "$SWARM_USER":"$SWARM_USER" /home/"$SWARM_USER"/.ssh

echo "Ansible installatie, repository update en permissies configuratie voltooid."

