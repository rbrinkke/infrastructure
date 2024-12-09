#!/bin/bash

# =============================================================================
# Script: initialize_vault.sh
# Doel: Automatisch initialiseren en ontzegelen van HashiCorp Vault
# Auteur: Rob Brinkkemper
# Datum: 2024-12-09
# =============================================================================

# Functie om fouten af te handelen
handle_error() {
  echo "Fout opgetreden op regel $1"
  exit 1
}

# Trap-functie om fouten op te vangen
trap 'handle_error $LINENO' ERR

# =============================================================================
# Stap 1: Stel de Vault adresomgeving in
# =============================================================================
echo "Stel VAULT_ADDR in..."
export VAULT_ADDR='http://127.0.0.1:8600'
echo "VAULT_ADDR ingesteld op $VAULT_ADDR"
echo

# =============================================================================
# Stap 2: Controleer of Vault bereikbaar is
# =============================================================================
echo "Controleer of Vault bereikbaar is..."
# Wacht tot Vault een response geeft op de health endpoint
RETRIES=10
COUNT=0
until curl -s $VAULT_ADDR/v1/sys/health | grep -q '"initialized":true'; do
  echo "Vault is nog niet bereikbaar. Wachten..."
  sleep 5
  COUNT=$((COUNT + 1))
  if [ $COUNT -ge $RETRIES ]; then
    echo "Vault is niet bereikbaar na $RETRIES pogingen. Script wordt gestopt."
    exit 1
  fi
done
echo "Vault is bereikbaar."
echo

# =============================================================================
# Stap 3: Controleer de Vault status
# =============================================================================
echo "Controleer Vault status..."
# Sla de output van 'vault status' op
VAULT_STATUS=$(vault status 2>&1)

# Check of het 'vault status' commando succesvol was
if echo "$VAULT_STATUS" | grep -q "Error"; then
  echo "Fout bij het ophalen van Vault status:"
  echo "$VAULT_STATUS"
  exit 1
fi

echo "$VAULT_STATUS"
echo

# Extract de status waarden
INITIALIZED=$(echo "$VAULT_STATUS" | grep "Initialized" | awk '{print $2}')
SEALED=$(echo "$VAULT_STATUS" | grep "Sealed" | awk '{print $2}')

echo "INITIALIZED: $INITIALIZED"
echo "SEALED: $SEALED"
echo

# =============================================================================
# Stap 4: Initialiseer Vault indien nog niet geïnitialiseerd
# =============================================================================
if [ "$INITIALIZED" == "false" ]; then
  echo "Vault is nog niet geïnitialiseerd. Initialiseren wordt gestart..."
  
  # Initialiseer Vault met 1 share en 1 threshold
  INIT_OUTPUT=$(vault operator init -key-shares=1 -key-threshold=1 2>&1)
  
  # Controleer of initialisatie succesvol was
  if echo "$INIT_OUTPUT" | grep -q "Error"; then
    echo "Fout bij het initialiseren van Vault:"
    echo "$INIT_OUTPUT"
    exit 1
  fi
  
  echo "Vault is geïnitialiseerd."
  echo
  
  # =============================================================================
  # Stap 5: Extract en bewaar de unseal key en root token
  # =============================================================================
  echo "Extracten van unseal key en root token..."
  
  # Extract unseal key
  UNSEAL_KEY=$(echo "$INIT_OUTPUT" | grep "Unseal Key 1" | awk '{print $NF}')
  
  # Extract root token
  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | grep "Initial Root Token" | awk '{print $NF}')
  
  echo "Unseal Key en Root Token zijn gegenereerd."
  echo
  
  # =============================================================================
  # Stap 6: Veilig opslaan van de sleutels
  # =============================================================================
  echo "⚠️ BELANGRIJK ⚠️"
  echo "Bewaar de volgende unseal key en root token veilig. Ze zijn essentieel voor de toegang tot Vault."
  echo "Kopieer ze naar een veilige locatie, zoals een beveiligd tekstbestand of een kluis."
  echo
  echo "========================================"
  echo "Unseal Key:"
  echo "$UNSEAL_KEY"
  echo "========================================"
  echo
  echo "========================================"
  echo "Root Token:"
  echo "$ROOT_TOKEN"
  echo "========================================"
  echo
  echo "Wil je de sleutels automatisch opslaan in bestanden? (y/n)"
  read -r SAVE_KEYS
  if [ "$SAVE_KEYS" == "y" ] || [ "$SAVE_KEYS" == "Y" ]; then
    echo "$UNSEAL_KEY" > ./unseal_key.txt
    echo "$ROOT_TOKEN" > ./root_token.txt
    echo "Unseal Key en Root Token zijn opgeslagen in unseal_key.txt en root_token.txt"
    echo "Zorg ervoor dat deze bestanden veilig zijn."
  fi
  
  echo "Druk op ENTER nadat je de sleutels veilig hebt opgeslagen."
  read -r
  
  # =============================================================================
  # Stap 7: Ontzegel Vault met de unseal key
  # =============================================================================
  echo "Ontzegel Vault met de unseal key..."
  
  # Ontzegel met de unseal key
  vault operator unseal "$UNSEAL_KEY"
  
  echo "Vault is nu ontzegeld."
  echo

# =============================================================================
# Stap 8: Ontzegel Vault indien al geïnitialiseerd maar verzegeld
# =============================================================================
elif [ "$SEALED" == "true" ]; then
  echo "Vault is geïnitialiseerd maar verzegeld. Ontzegelen wordt gestart."
  
  # Prompt de gebruiker voor de unseal key
  echo "Voer de unseal key in om Vault te ontzegelen."
  read -s -p "Unseal Key: " UNSEAL_KEY_INPUT
  echo
  
  # Trim whitespace from input
  UNSEAL_KEY_INPUT=$(echo "$UNSEAL_KEY_INPUT" | xargs)
  
  # Controleer of de unseal key niet leeg is
  if [ -z "$UNSEAL_KEY_INPUT" ]; then
    echo "Geen unseal key ingevoerd. Script wordt gestopt."
    exit 1
  fi
  
  # Ontzegel met de ingevoerde unseal key
  vault operator unseal "$UNSEAL_KEY_INPUT"
  
  # Controleer of unseal succesvol was
  NEW_STATUS=$(vault status | grep "Sealed" | awk '{print $2}')
  
  if [ "$NEW_STATUS" == "false" ]; then
    echo "Vault is nu ontzegeld."
  else
    echo "Vault is nog steeds verzegeld. Controleer de unseal key en probeer opnieuw."
    exit 1
  fi
  
  echo
# =============================================================================
# Stap 9: Vault is al geïnitialiseerd en niet verzegeld
# =============================================================================
else
  echo "Vault is al geïnitialiseerd en niet verzegeld. Niets te doen."
  echo
fi

# =============================================================================
# Stap 10: Controleer de Vault status opnieuw
# =============================================================================
echo "Controleer Vault status na initialisatie en/of ontzegeling..."
vault status
echo

# =============================================================================
# Stap 11: Toegang tot de Vault UI via Traefik
# =============================================================================
echo "Vault is nu toegankelijk via de UI via Traefik op:"
echo "https://vault.example.com"
echo "Gebruik het root token om in te loggen via de UI."
echo

echo "✔️ Vault initialisatie en ontzegeling voltooid."

