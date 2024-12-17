#!/bin/bash

# Pad naar de bestanden
FILE1="/home/rob/actions-runner/actions-runner/_work/infrastructure/infrastructure/terraform/terraform.tfstate"
FILE2="/home/rob/repos/infrastructure/terraform/terraform.tfstate"

# Controleer welke versie nieuwer is en kopieer die naar de andere locatie
if [ "$FILE1" -nt "$FILE2" ]; then
  echo "Kopieer nieuwere versie van $FILE1 naar $FILE2"
  cp "$FILE1" "$FILE2"
elif [ "$FILE2" -nt "$FILE1" ]; then
  echo "Kopieer nieuwere versie van $FILE2 naar $FILE1"
  cp "$FILE2" "$FILE1"
else
  echo "Beide bestanden zijn al up-to-date."
fi
terraform apply -auto-approve
