#!/bin/bash

# Map waarin de Terraform-bestanden zich bevinden
TF_DIRECTORY="$HOME/repos/infrastructure/terraform"

# Controleer of de map bestaat
if [ ! -d "$TF_DIRECTORY" ]; then
    echo "De map $TF_DIRECTORY bestaat niet. Controleer het pad en probeer opnieuw."
    exit 1
fi

# Zoek alle Terraform-bestanden (.tf) in de map en submappen
TF_FILES=$(find "$TF_DIRECTORY" -type f -name "*.tf")

# Controleer of er .tf-bestanden zijn gevonden
if [ -z "$TF_FILES" ]; then
    echo "Geen .tf-bestanden gevonden in $TF_DIRECTORY."
    exit 0
fi

# Itereer over elk .tf-bestand
for FILE in $TF_FILES; do
    # Maak het bestand leeg
    > "$FILE"
    echo "Bestand leeggemaakt: $FILE"
    
    # Open het bestand met vi voor bewerking
    vi "$FILE"
done

echo "Alle bestanden zijn leeggemaakt en geopend in vi."

