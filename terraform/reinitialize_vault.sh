#!/bin/bash

# =============================================================================
# Script: reinitialize_vault.sh
# Doel: Herinitialiseren en ontzegelen van HashiCorp Vault
# Auteur: Rob Brinkkemper
# Datum: 2024-12-09
# =============================================================================

# Foutenafhandeling
set -e

# Functie om fouten af te handelen
handle_error() {
  echo "❌ Fout opgetreden op regel $1"
  echo "Laatste commando exit status: $?"
  exit 1
}

# Trap-functie om fouten op te vangen
trap 'handle_error $LINENO' ERR

# Functie om de Vault status te controleren met de Vault CLI
check_vault_status() {
  echo "🔍 Controleer Vault status via Vault CLI..."

  VAULT_STATUS=$(vault status 2>&1)

  # Check of het 'vault status' commando succesvol was
  if echo "$VAULT_STATUS" | grep -q "Error"; then
    echo "❌ Fout bij het ophalen van Vault status:"
    echo "$VAULT_STATUS"
    exit 1
  fi

  echo "$VAULT_STATUS"
  echo

  # Extract de status waarden
  VAULT_INITIALIZED=$(echo "$VAULT_STATUS" | grep "Initialized" | awk '{print $2}')
  VAULT_SEALED=$(echo "$VAULT_STATUS" | grep "Sealed" | awk '{print $2}')

  echo "📊 Vault Status:"
  echo "- Geïnitialiseerd: $VAULT_INITIALIZED"
  echo "- Verzegeld: $VAULT_SEALED"
  echo
}

# =============================================================================
# Start van het script
# =============================================================================
echo "🚀 Start herinitialisatie Vault script..."
echo

# =============================================================================
# Stap 1: Stel de Vault adresomgeving in
# =============================================================================
echo "🔧 Stel VAULT_ADDR in..."
export VAULT_ADDR='http://127.0.0.1:8600'
echo "✔️ VAULT_ADDR ingesteld op $VAULT_ADDR"
echo

# =============================================================================
# Stap 2: Controleer of Vault bereikbaar is
# =============================================================================
echo "🔄 Controleer of Vault bereikbaar is..."

# Installeer jq als het nog niet aanwezig is
if ! command -v jq &> /dev/null; then
    echo "📦 Installeer jq..."
    sudo apt-get update && sudo apt-get install -y jq
fi

RETRIES=10
COUNT=0
until vault status > /dev/null 2>&1; do
  echo "⏳ Wachten op Vault... Poging $((COUNT + 1))/$RETRIES"
  sleep 5
  COUNT=$((COUNT + 1))
  if [ $COUNT -ge $RETRIES ]; then
    echo "❌ Vault is niet bereikbaar na $RETRIES pogingen. Script wordt gestopt."
    exit 1
  fi
done

echo "✔️ Vault is bereikbaar"
echo

# =============================================================================
# Stap 3: Controleer de Vault status
# =============================================================================
check_vault_status

# =============================================================================
# Stap 4: Initialiseer Vault indien niet geïnitieerd
# =============================================================================
if [[ "$VAULT_INITIALIZED" == "false" ]]; then
    echo "🔧 Vault is niet geïnitialiseerd. Start initialisatie..."

    # Initialiseer Vault met 1 share en 1 threshold
    init_output=$(vault operator init -key-shares=1 -key-threshold=1)

    # Controleer of initialisatie succesvol was
    if echo "$init_output" | grep -q "Error"; then
      echo "❌ Fout bij het initialiseren van Vault:"
      echo "$init_output"
      exit 1
    fi

    # Bewaar keys en token
    echo "$init_output" | grep "Unseal Key" | awk '{print $NF}' > vault_keys.txt
    echo "$init_output" | grep "Initial Root Token" | awk '{print $NF}' > vault_root_token.txt

    echo "✔️ Vault geïnitialiseerd"
    echo "📝 Keys opgeslagen in vault_keys.txt"
    echo "🔑 Root token opgeslagen in vault_root_token.txt"

    echo "⚠️ BELANGRIJK: Bewaar deze bestanden op een veilige plaats!"

    # Ontzegel Vault met de unseal key
    UNSEAL_KEY=$(head -n1 vault_keys.txt)
    echo "🔓 Ontzegel Vault met de unseal key..."
    vault operator unseal "$UNSEAL_KEY"

    echo "✔️ Vault is succesvol ontzegeld."
    echo
else
    echo "✅ Vault is al geïnitialiseerd."
    echo
fi

# =============================================================================
# Stap 5: Controleer de Vault status opnieuw
# =============================================================================
echo "🔍 Controleer Vault status na initialisatie en/of ontzegeling..."
vault status
echo

# =============================================================================
# Stap 6: Vault UI Toegang
# =============================================================================
echo "🌐 Vault is nu toegankelijk via:"
echo "📍 UI: https://vault.example.com"
echo "🔑 API: $VAULT_ADDR"
echo

echo "✨ Vault setup voltooid!"

