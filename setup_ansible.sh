#!/bin/bash

# setup_ansible.sh
# Doel: Installeer Ansible, configureer SSH-sleutels voor swarm_user, vervang placeholders, en verifieer de setup

set -e

# Variabelen
SWARM_USER="swarm_user"
SWARM_MANAGER_IP="192.168.178.183"
ANSIBLE_DIR="/home/rob/repos/infrastructure/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory.yml"
PLAYBOOK_FILE="$ANSIBLE_DIR/playbook.yml"
SSH_DIR="/home/$SWARM_USER/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Functie om commando's uit te voeren en fouten te controleren
run_cmd() {
    echo ">> $1"
    eval $1
}

# Zorg dat het script wordt uitgevoerd als swarm_user
if [ "$(whoami)" != "$SWARM_USER" ]; then
    echo "Dit script moet worden uitgevoerd als $SWARM_USER."
    exit 1
fi

# Stap 1: Installeer Ansible en vereiste pakketten
run_cmd "sudo apt update"
run_cmd "sudo apt install -y software-properties-common acl git"

# Voeg Ansible PPA toe en installeer Ansible
run_cmd "sudo add-apt-repository --yes --update ppa:ansible/ansible"
run_cmd "sudo apt install -y ansible"

# Verifieer Ansible installatie
ansible-playbook --version

# Stap 2: Genereer SSH-sleutel voor swarm_user indien nog niet aanwezig
if [ ! -f "$PRIVATE_KEY" ]; then
    echo "Genereer SSH-sleutel voor $SWARM_USER..."
    run_cmd "ssh-keygen -t rsa -b 4096 -f $PRIVATE_KEY -N '' -C '$SWARM_USER@docker-host01-dev'"
else
    echo "SSH-sleutel voor $SWARM_USER bestaat al."
fi

# Stel permissies in voor .ssh directory en sleutels
run_cmd "chmod 700 $SSH_DIR"
run_cmd "chmod 600 $PRIVATE_KEY"
run_cmd "chmod 644 $PUBLIC_KEY"

# Stap 3: Voeg de public key toe aan authorized_keys op de swarm manager
echo "Voeg public key toe aan authorized_keys op de swarm manager ($SWARM_MANAGER_IP)..."

# Gebruik ssh-copy-id als mogelijk
if command -v ssh-copy-id &> /dev/null; then
    run_cmd "ssh-copy-id -i $PUBLIC_KEY -o StrictHostKeyChecking=no $SWARM_USER@$SWARM_MANAGER_IP"
else
    # Als ssh-copy-id niet beschikbaar is, gebruik scp en voeg handmatig toe
    echo "Gebruik scp en voeg handmatig toe als ssh-copy-id niet beschikbaar is."
    run_cmd "scp -o StrictHostKeyChecking=no $PUBLIC_KEY $SWARM_USER@$SWARM_MANAGER_IP:/tmp/temp_pub_key.pub"
    run_cmd "ssh -o StrictHostKeyChecking=no $SWARM_USER@$SWARM_MANAGER_IP 'mkdir -p ~/.ssh && cat /tmp/temp_pub_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/temp_pub_key.pub'"
fi

# Stel permissies in voor authorized_keys
run_cmd "chmod 600 $AUTHORIZED_KEYS"
run_cmd "chown -R $SWARM_USER:$SWARM_USER $SSH_DIR"

# Stap 4: Update inventory.yml met het juiste SSH private key pad
echo "Update inventory.yml met het juiste SSH private key pad..."
if grep -q "ansible_ssh_private_key_file" "$INVENTORY_FILE"; then
    echo "ansible_ssh_private_key_file is al ingesteld in inventory.yml"
else
    run_cmd "echo 'ansible_ssh_private_key_file: $PRIVATE_KEY' >> $INVENTORY_FILE"
fi

# Vervang 'your_swarm_manager_ip' met het correcte IP in inventory.yml en playbook.yml
echo "Vervang 'your_swarm_manager_ip' met '$SWARM_MANAGER_IP' in inventory.yml en playbook.yml"
run_cmd "sed -i 's/your_swarm_manager_ip/$SWARM_MANAGER_IP/g' $INVENTORY_FILE"
run_cmd "sed -i 's/your_swarm_manager_ip/$SWARM_MANAGER_IP/g' $PLAYBOOK_FILE"

# Controleer permissies van Ansible directory
echo "Controleer permissies van Ansible directory:"
ls -ld "$ANSIBLE_DIR"
ls -l "$ANSIBLE_DIR"

# Stap 5: Test Ansible verbinding met een simpele ping
echo "Voer een test Ansible playbook uit om de verbinding te verifiëren."
ansible -i "$INVENTORY_FILE" swarm-manager -m ping -vvv

echo "Setup en verificatie voltooid."

