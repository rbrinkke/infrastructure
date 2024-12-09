#!/bin/bash

# Script: generate_summary.sh
# Doel: Genereer een overzicht van alle .tf bestanden in de opgegeven map met hun inhoud.

# Bestand waarin de samenvatting wordt opgeslagen
OUTPUT_FILE="project_summary.txt"

# Map waarin de .tf bestanden zich bevinden
TF_DIRECTORY="$HOME/repos/infrastructure/terraform"

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

# Vind alle .tf bestanden in de opgegeven map
TF_FILES=$(find "$TF_DIRECTORY" -type f -name "*.tf")

# Controleer of er .tf bestanden zijn gevonden
if [ -z "$TF_FILES" ]; then
    echo "Geen .tf bestanden gevonden in $TF_DIRECTORY"
    exit 1
fi

# Itereer over de gevonden .tf bestanden
for FILE in $TF_FILES; do
    if [ -e "$FILE" ]; then
        REL_PATH="${FILE#$HOME/}"
        ABS_PATH=$(get_absolute_path "$FILE")
        echo "### $REL_PATH" >> "$OUTPUT_FILE"
        echo "Pad: $ABS_PATH" >> "$OUTPUT_FILE"
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

