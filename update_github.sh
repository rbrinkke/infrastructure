#!/bin/bash

# Controleer of een commitbericht is opgegeven
if [ -z "$1" ]; then
  echo "Gebruik: $0 '<commit-bericht>'"
  exit 1
fi

# Variabele voor commitbericht
COMMIT_MESSAGE="$1"

# Pad naar de repository (optioneel aanpassen als nodig)
REPO_PATH=$(pwd)

# Start
echo "===== GitHub Update Script ====="
echo "Repository: $REPO_PATH"
echo "Commit-bericht: $COMMIT_MESSAGE"
echo ""

# Controleer of dit een Git-repository is
if [ ! -d "$REPO_PATH/.git" ]; then
  echo "ERROR: Dit is geen geldige Git-repository: $REPO_PATH"
  exit 1
fi

# Stap 1: Controleer status
echo "1. Controleer repository-status..."
git status
echo ""

# Stap 2: Voeg wijzigingen toe
echo "2. Voeg wijzigingen toe..."
git add .
if [ $? -ne 0 ]; then
  echo "ERROR: Kon geen wijzigingen toevoegen."
  exit 1
fi
echo "   - Wijzigingen toegevoegd."
echo ""

# Stap 3: Commit wijzigingen
echo "3. Commit wijzigingen..."
git commit -m "$COMMIT_MESSAGE"
if [ $? -ne 0 ]; then
  echo "ERROR: Commit mislukt."
  exit 1
fi
echo "   - Commit succesvol gemaakt."
echo ""

# Stap 4: Push wijzigingen naar GitHub
echo "4. Push wijzigingen naar GitHub..."
git push origin main
if [ $? -ne 0 ]; then
  echo "ERROR: Push naar GitHub mislukt."
  exit 1
fi
echo "   - Push succesvol uitgevoerd."
echo ""

# Einde
echo "===== Update voltooid ====="
