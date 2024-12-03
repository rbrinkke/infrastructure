#!/bin/bash
# Controleert Ansible-bestanden op de doelhost.

# Configuratie
ANSIBLE_PATH="/home/rob/repos/infrastructure/ansible"
FILES_TO_CHECK=("playbook.yml" "inventory.yml")

echo "===== Controleer Ansible Bestanden ====="

# Controleer aanwezigheid van Ansible-bestanden
for FILE in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$ANSIBLE_PATH/$FILE" ]; then
        echo "   - Bestand $FILE gevonden."
    else
        echo "   - ERROR: Bestand $FILE ontbreekt."
    fi
done

echo "===== Controle voltooid ====="

