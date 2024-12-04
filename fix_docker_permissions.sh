#!/bin/bash

CONTAINER_ID="act-Build-and-Push-Docker-Image-build-6d38bd0a83bc4faeee92a765bea81f5a9596c047789317fc963f710552e027bf"
VOLUME_ID="bea431e08c67f82db8b19d8800377aa6fb8fcd7547c334fe4d4405483fbcbb71"
DOCKER_SOCKET="/var/run/docker.sock"
LOGFILE="fix_docker.log"

echo "===== Docker Permissions Fix Script =====" | tee $LOGFILE

# Controleer of gebruiker in Docker-groep zit
echo "Controleer of gebruiker in Docker-groep zit..." | tee -a $LOGFILE
if groups $USER | grep -q docker; then
    echo "✅ Gebruiker zit al in de Docker-groep." | tee -a $LOGFILE
else
    echo "🔧 Voeg gebruiker toe aan Docker-groep..." | tee -a $LOGFILE
    sudo usermod -aG docker $USER | tee -a $LOGFILE
fi

# Controleer en herstel permissies op Docker-socket
echo "Controleer permissies van Docker-socket..." | tee -a $LOGFILE
DOCKER_SOCKET_PERMS=$(stat -c "%a" $DOCKER_SOCKET)
if [[ $DOCKER_SOCKET_PERMS != "660" ]]; then
    echo "🔧 Herstel Docker-socket permissies..." | tee -a $LOGFILE
    sudo chmod 660 $DOCKER_SOCKET | tee -a $LOGFILE
    sudo chgrp docker $DOCKER_SOCKET | tee -a $LOGFILE
else
    echo "✅ Docker-socket permissies zijn correct." | tee -a $LOGFILE
fi

# Herstart Docker-service
echo "🔄 Herstart Docker-service..." | tee -a $LOGFILE
sudo systemctl daemon-reload | tee -a $LOGFILE
sudo systemctl restart docker | tee -a $LOGFILE

# Verwijder container
echo "🗑️ Container verwijderen ($CONTAINER_ID)..." | tee -a $LOGFILE
sudo docker rm -f $CONTAINER_ID &>> $LOGFILE
if [[ $? -eq 0 ]]; then
    echo "✅ Container succesvol verwijderd." | tee -a $LOGFILE
else
    echo "⚠️  Container verwijderen mislukt. Controleer handmatig." | tee -a $LOGFILE
fi

# Verwijder gekoppeld volume
echo "🗑️ Volume verwijderen ($VOLUME_ID)..." | tee -a $LOGFILE
sudo docker volume rm $VOLUME_ID &>> $LOGFILE
if [[ $? -eq 0 ]]; then
    echo "✅ Volume succesvol verwijderd." | tee -a $LOGFILE
else
    echo "⚠️  Volume verwijderen mislukt. Controleer handmatig." | tee -a $LOGFILE
fi

echo "===== Alle stappen zijn uitgevoerd =====" | tee -a $LOGFILE

# Toon volledige log
echo "🔍 Toon volledige log:"
cat $LOGFILE

