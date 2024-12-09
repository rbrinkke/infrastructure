#!/bin/bash

# Specificeer hier de directory die je wilt negeren
TARGET_DIRS=("terraform/auth/postgres-data/" "terraform/vault/vault-data/")

# Zorg dat je een .gitignore bestand hebt, maak er een als het nog niet bestaat
touch .gitignore

for DIR in "${TARGET_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        echo "Processing directory: $DIR"
        # Voeg alle bestanden en mappen in de directory toe aan .gitignore
        find "$DIR" -type f -o -type d | while read -r LINE; do
            # Controleer of het pad al in .gitignore staat
            if ! grep -qx "$LINE" .gitignore; then
                echo "$LINE" >> .gitignore
            fi
        done
    else
        echo "Directory $DIR does not exist, skipping..."
    fi
done

echo "Alle bestanden en mappen in de opgegeven directories zijn toegevoegd aan .gitignore."

