#!/bin/bash

# Environment Verification Script for Infrastructure Project

# Functie om te controleren of een commando bestaat
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "🔍 Starten met omgeving verificatie..."

# Controleer Git
if command_exists git; then
    echo "✅ Git is geïnstalleerd."
else
    echo "❌ Git is niet geïnstalleerd. Installeer Git en probeer het opnieuw."
    exit 1
fi

# Controleer Docker
if command_exists docker; then
    echo "✅ Docker is geïnstalleerd."
    if sudo docker info >/dev/null 2>&1; then
        echo "✅ Docker daemon draait."
    else
        echo "❌ Docker daemon draait niet. Start Docker en probeer het opnieuw."
        exit 1
    fi
else
    echo "❌ Docker is niet geïnstalleerd. Installeer Docker en probeer het opnieuw."
    exit 1
fi

# Controleer Docker Swarm
if sudo docker info | grep -q "Swarm: active"; then
    echo "✅ Docker Swarm is geïnitieerd."
else
    echo "⚠️ Docker Swarm is niet geïnitieerd. Initialiseren Docker Swarm..."
    sudo docker swarm init
    if [ $? -eq 0 ]; then
        echo "✅ Docker Swarm succesvol geïnitieerd."
    else
        echo "❌ Docker Swarm initialisatie mislukt."
        exit 1
    fi
fi

# Controleer Docker Compose
if command_exists docker-compose; then
    echo "✅ Docker Compose is geïnstalleerd."
else
    echo "❌ Docker Compose is niet geïnstalleerd. Installeer Docker Compose en probeer het opnieuw."
    exit 1
fi

# Controleer Terraform
if command_exists terraform; then
    echo "✅ Terraform is geïnstalleerd."
else
    echo "❌ Terraform is niet geïnstalleerd. Installeer Terraform en probeer het opnieuw."
    exit 1
fi

# Controleer Ansible
if command_exists ansible; then
    echo "✅ Ansible is geïnstalleerd."
else
    echo "❌ Ansible is niet geïnstalleerd. Installeer Ansible en probeer het opnieuw."
    exit 1
fi

# Controleer of huidige directory een Git repository is
if [ -d ".git" ]; then
    echo "✅ Huidige directory is een Git repository."
else
    echo "❌ Huidige directory is geen Git repository. Initialiseren Git..."
    git init
    if [ $? -eq 0 ]; then
        echo "✅ Git succesvol geïnitialiseerd."
    else
        echo "❌ Git initialisatie mislukt."
        exit 1
    fi
fi

# Controleer of remote 'origin' is ingesteld
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ Git remote 'origin' is ingesteld op: $REMOTE_URL"
else
    echo "❌ Git remote 'origin' is niet ingesteld. Voeg de remote repository toe met:"
    echo "   git remote add origin https://github.com/jouwgebruikersnaam/infrastructure.git"
    exit 1
fi

# Controleer huidige branch (main of master)
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" == "main" ]; then
    echo "✅ Huidige Git branch is 'main'."
elif [ "$CURRENT_BRANCH" == "master" ]; then
    echo "⚠️ Huidige Git branch is 'master'. Overweeg deze te hernoemen naar 'main'."
else
    echo "⚠️ Huidige Git branch is '$CURRENT_BRANCH'. Zorg ervoor dat deze overeenkomt met je GitHub repository."
fi

# Controleer of er ten minste één commit bestaat
if git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "✅ Git repository heeft commits."
else
    echo "❌ Git repository heeft geen commits. Maak een initiële commit met:"
    echo "   git add ."
    echo "   git commit -m 'Initial commit with project structure'"
    exit 1
fi

# Controleer projectstructuur
required_dirs=(
    ".github/workflows"
    "terraform"
    "ansible"
    "services/traefik"
    "services/prometheus"
    "services/grafana"
    "services/web"
    "services/redis"
    "services/keycloak"
    "services/postgres"
    "services/couchdb"
    "services/minio"
)
required_files=(
    ".github/workflows/ci-cd.yml"
    "terraform/main.tf"
    "terraform/variables.tf"
    "terraform/outputs.tf"
    "ansible/inventory.yml"
    "ansible/playbook.yml"
    "docker-compose.yml"
    "README.md"
)

echo "✅ Controleren van project directory structuur..."

# Controleer directories
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ Directory bestaat: $dir"
    else
        echo "❌ Directory ontbreekt: $dir"
    fi
done

# Controleer bestanden
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ Bestand bestaat: $file"
    else
        echo "❌ Bestand ontbreekt: $file"
    fi
done

# Optioneel: Lijst ontbrekende directories en bestanden
missing_dirs=()
missing_files=()

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        missing_dirs+=("$dir")
    fi
done

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_dirs[@]} -eq 0 ] && [ ${#missing_files[@]} -eq 0 ]; then
    echo "✅ Alle vereiste directories en bestanden zijn aanwezig."
else
    echo "❌ Sommige directories of bestanden ontbreken."
    if [ ${#missing_dirs[@]} -ne 0 ]; then
        echo "Ontbrekende directories:"
        for dir in "${missing_dirs[@]}"; do
            echo "  - $dir"
        done
    fi
    if [ ${#missing_files[@]} -ne 0 ]; then
        echo "Ontbrekende bestanden:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
    fi
    exit 1
fi

# Samenvatting
echo "🔍 Omgeving verificatie voltooid! 🎉"

exit 0
