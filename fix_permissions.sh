#!/bin/bash

# Script om permissies en groepsinstellingen te herstellen voor swarm_user toegang tot het project

# Variabelen
PROJECT_PATH="/home/rob/repos/infrastructure"
ROB_HOME="/home/rob"
SWARM_USER_HOME="/home/swarm_user"
GROUP_NAME="project_group"
LOG_FILE="/home/rob/fix_permissions.log"

# Start logging
exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "===== START FIX PERMISSIES ====="
echo "Datum en tijd: $(date)"
echo ""

# 1. Installeer ACL-tools indien nodig
echo "1. Controleer en installeer ACL-tools..."
if ! command -v getfacl &> /dev/null || ! command -v setfacl &> /dev/null
then
    echo "   - ACL-tools niet gevonden. Installeren..."
    sudo apt update
    sudo apt install -y acl
    echo "   - ACL-tools geïnstalleerd."
else
    echo "   - ACL-tools zijn al geïnstalleerd."
fi
echo ""

# 2. Herstel eigenaar en groepen
echo "2. Herstel eigenaar en groepsinstellingen..."
# Eigenaar van rob_home
sudo chown -R rob:rob "$ROB_HOME"
# Eigenaar van swarm_user_home
sudo chown -R swarm_user:swarm_user "$SWARM_USER_HOME"
# Groep van project_path
sudo chgrp -R "$GROUP_NAME" "$PROJECT_PATH"
echo "   - Eigenaar en groepsinstellingen hersteld."
echo ""

# 3. Instellen van permissies
echo "3. Instellen van permissies..."
# Permissies voor /home
sudo chmod 755 /home
echo "   - Permissies voor /home ingesteld op 755."
# Permissies voor /home/rob
sudo chmod 750 "$ROB_HOME"
echo "   - Permissies voor $ROB_HOME ingesteld op 750."
# Permissies voor /home/rob/repos
sudo chmod 750 "$ROB_HOME/repos"
echo "   - Permissies voor $ROB_HOME/repos ingesteld op 750."
# Permissies voor project_path
sudo chmod -R 770 "$PROJECT_PATH"
sudo chmod g+s "$PROJECT_PATH"
echo "   - Permissies voor $PROJECT_PATH en submappen ingesteld op 770 met setgid."
echo ""

# 4. Toepassen van ACL's
echo "4. Toepassen van ACL's..."
# Geef project_group execute rechten op /home/rob
sudo setfacl -m g:"$GROUP_NAME":x "$ROB_HOME"
echo "   - Execute rechten voor $GROUP_NAME toegevoegd aan $ROB_HOME."
# Geef project_group lees- en execute rechten op /home/rob/repos
sudo setfacl -m g:"$GROUP_NAME":rx "$ROB_HOME/repos"
echo "   - Lees- en execute rechten voor $GROUP_NAME toegevoegd aan $ROB_HOME/repos."
# Geef project_group volledige rechten op project_path en submappen
sudo setfacl -R -m g:"$GROUP_NAME":rwx "$PROJECT_PATH"
sudo setfacl -R -m d:g:"$GROUP_NAME":rwx "$PROJECT_PATH"
echo "   - Volledige rechten voor $GROUP_NAME toegevoegd aan $PROJECT_PATH en submappen."
echo ""

# 5. Verwijder restrictieve ACL's indien aanwezig
echo "5. Verwijderen van restrictieve ACL's indien aanwezig..."
sudo setfacl -bR "$PROJECT_PATH"
echo "   - Alle bestaande ACL's op $PROJECT_PATH en submappen verwijderd."
echo ""

# 6. Herstel swarm_user home directory
echo "6. Herstel swarm_user home directory..."
sudo chmod 750 "$SWARM_USER_HOME"
echo "   - Permissies voor $SWARM_USER_HOME ingesteld op 750."
echo ""

# 7. Hercontrole en log output
echo "7. Hercontrole permissies en groepslidmaatschappen..."
echo "   - Permissies en eigenaarschap van mappen:"
ls -ld /home
ls -ld "$ROB_HOME"
ls -ld "$ROB_HOME/repos"
ls -ld "$PROJECT_PATH"
ls -ld "$PROJECT_PATH/ansible"
echo ""
echo "   - Groepslidmaatschappen van swarm_user:"
groups swarm_user
echo ""

# 8. Test toegang als swarm_user
echo "8. Test toegang als swarm_user..."
sudo -u swarm_user ls -ld "$PROJECT_PATH" &> /dev/null
if [ $? -eq 0 ]; then
    echo "   - SUCCESS: swarm_user heeft toegang tot $PROJECT_PATH"
else
    echo "   - ERROR: swarm_user heeft nog steeds geen toegang tot $PROJECT_PATH"
fi
echo ""

echo "===== FIX PERMISSIES COMPLETED ====="
echo "Bekijk het logbestand voor meer details: $LOG_FILE"
