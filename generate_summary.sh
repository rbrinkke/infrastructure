#!/bin/bash

# Script: generate_summary.sh
# Doel: Genereer een overzicht van belangrijke bestanden met hun inhoud.

# Bestand waarin de samenvatting wordt opgeslagen
OUTPUT_FILE="project_summary.txt"

# Lijst van belangrijke bestanden en mappen (relatief aan de projectroot)
IMPORTANT_FILES=(
    "ansible/inventory.yml"
    "ansible/playbook.yml"
    "docker-compose.yml"
    "Dockerfile"
    "fix_docker.log"
    "generate_project_summary.py"
    "LICENSE"
    "project_summary.txt"
    "README.md"
    "terraform/main.tf"
    "terraform/outputs.tf"
    "terraform/variables.tf"
    "update_github.sh"
)

# Voeg hier eventueel meer belangrijke bestanden of patronen toe
# Bijvoorbeeld: "services/*/config.yml" voor configuratiebestanden in services

# Verwijder het oude samenvattingsbestand als het bestaat
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# Begin met het schrijven van de samenvatting
echo "Project Samenvatting - $(date)" > "$OUTPUT_FILE"
echo "====================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Functie om absolute pad te krijgen
get_absolute_path() {
    realpath "$1" 2>/dev/null
}

# Itereer over de belangrijke bestanden
for FILE in "${IMPORTANT_FILES[@]}"; do
    if [ -e "$FILE" ]; then
        ABS_PATH=$(get_absolute_path "$FILE")
        echo "### $FILE" >> "$OUTPUT_FILE"
        echo "Path: $ABS_PATH" >> "$OUTPUT_FILE"
        echo "------------------------------------" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Voeg de inhoud van het bestand toe
        cat "$FILE" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "====================================" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    else
        echo "Waarschuwing: $FILE bestaat niet en wordt overgeslagen."
    fi
done

echo "Samenvatting gegenereerd in $OUTPUT_FILE"

