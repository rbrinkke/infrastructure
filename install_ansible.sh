#!/bin/bash

# Script: install_ansible.sh
# Doel: Installeer Ansible via APT en configureer permissies voor swarm_user

# Functie om een commando uit te voeren en te controleren op fouten
run_cmd() {
    echo ">> $1"
    eval $1
    if [ $? -ne 0 ]; then
        echo "Fout bij uitvoeren van: $1"
        exit 1
    fi
}

# Update het pakketbeheer
run_cmd "sudo apt update"

# Installeer prerequisites
run_cmd "sudo apt install -y software-properties-common"

# Voeg de Ansible PPA toe
run_cmd "sudo add-apt-repository --yes --update ppa:ansible/ansible"

# Installeer Ansible
run_cmd "sudo apt install -y ansible"

# Verifieer de installatie
run_cmd "ansible --version"

# Controleer of swarm_user bestaat
if id "swarm_user" &>/dev/null; then
    echo "Gebruiker 'swarm_user' bestaat."
else
    echo "Gebruiker 'swarm_user' bestaat niet. Aanmaken..."
    run_cmd "sudo adduser --disabled-password --gecos '' swarm_user"
fi

# Voeg swarm_user toe aan de sudo groep (optioneel, indien nodig)
# Uncomment de volgende regel als swarm_user sudo-rechten nodig heeft zonder wachtwoord
# run_cmd "echo 'swarm_user ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/swarm_user"

# Stel de permissies in voor de Ansible directory
ANSIBLE_DIR="/home/rob/repos/infrastructure/ansible"

# Controleer of de directory bestaat
if [ -d "$ANSIBLE_DIR" ]; then
    echo "Directory $ANSIBLE_DIR bestaat."
else
    echo "Directory $ANSIBLE_DIR bestaat niet. Aanmaken..."
    run_cmd "sudo mkdir -p $ANSIBLE_DIR"
fi

# Pas eigenaarschap en permissies aan
run_cmd "sudo chown -R rob:rob $ANSIBLE_DIR"
run_cmd "sudo chmod -R 750 $ANSIBLE_DIR"

# Geef swarm_user toegang via ACL
run_cmd "sudo apt install -y acl"  # Installeer ACL indien nog niet geïnstalleerd
run_cmd "sudo setfacl -m u:swarm_user:rx $ANSIBLE_DIR"
run_cmd "sudo setfacl -R -m u:swarm_user:rx $ANSIBLE_DIR"

# Voeg de SSH-sleutel toe aan authorized_keys van swarm_user (indien nog niet gedaan)
AUTHORIZED_KEYS="/home/swarm_user/.ssh/authorized_keys"

# Maak de .ssh directory aan indien deze nog niet bestaat
run_cmd "sudo mkdir -p /home/swarm_user/.ssh"

# Stel de juiste permissies in
run_cmd "sudo chmod 700 /home/swarm_user/.ssh"
wq
# Voeg de public key toe (vervang <YOUR_PUBLIC_KEY> door je daadwerkelijke public key)
# Bijvoorbeeld: "ssh-rsa AAAAB3Nza... swarm_user@docker-host01-dev"
echo "Voeg de public key toe aan $AUTHORIZED_KEYS:"
read -p "Plak hier de public key: " PUBLIC_KEY
echo "$PUBLIC_KEY" | sudo tee -a $AUTHORIZED_KEYS

# Stel de juiste permissies in voor authorized_keys
run_cmd "sudo chmod 600 $AUTHORIZED_KEYS"
run_cmd "sudo chown -R swarm_user:swarm_user /home/swarm_user/.ssh"

echo "Ansible installatie en configuratie voltooid."
