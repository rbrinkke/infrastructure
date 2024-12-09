#!/bin/bash

# =============================================================================
# Script: initialize_vault.sh
# Doel: Automatisch initialiseren en ontzegelen van HashiCorp Vault
# Auteur: Rob Brinkkemper
# Datum: 2024-12-09
# =============================================================================

# Foutenafhandeling
set -e

# Functie om fouten af te handelen
handle_error() {
  echo "❌ Fout opgetreden op regel $1"
  echo "Laatste commando exit status: $?"
  echo "Stack trace:"
  local frame=0
  while caller $frame; do
    ((frame++))
  done
  exit 1
}

# Trap-functie om fouten op te vangen
trap 'handle_error $LINENO' ERR

# Functie om de Vault status te controleren met curl
check_vault_status() {
  local response
  local status_code
  
  echo "🔍 Controleer Vault status via HTTP API..."
  
  response=$(curl -s -w "\n%{http_code}" $VAULT_ADDR/v1/sys/seal-status)
  status_code=$(echo "$response" | tail -n1)
  response_body=$(echo "$response" | head -n-1)
  
  echo "Debug: HTTP Status Code: $status_code"
  echo "Debug: Response Body: $response_body"
  
  if [ "$status_code" = "200" ]; then
    echo "✔️ Vault is bereikbaar en reageert"
    
    # Parse status informatie
    initialized=$(echo "$response_body" | jq -r '.initialized')
    sealed=$(echo "$response_body" | jq -r '.sealed')
    
    echo "📊 Vault Status:"
    echo "- Geïnitialiseerd: $initialized"
    echo "- Verzegeld: $sealed"
    
    VAULT_INITIALIZED=$initialized
    VAULT_SEALED=$sealed
  else
    echo "❌ Kan geen verbinding maken met Vault. Status code: $status_code"
    return 1
  fi
}

# =============================================================================
# Start van het script
# =============================================================================
echo "🚀 Start Vault initialisatie script..."
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
until curl -s -f $VAULT_ADDR/v1/sys/health > /dev/null; do
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
# Stap 4: Handel dev mode af
# =============================================================================
echo "🔍 Controleer of Vault in development mode draait..."

dev_mode_check=$(curl -s $VAULT_ADDR/v1/sys/seal-status | jq -r '.type')
if [[ "$dev_mode_check" == "shamir" ]] && [[ "$VAULT_SEALED" == "false" ]]; then
    echo "ℹ️ Vault draait in development mode"
    echo "Root Token: root"
    echo
    echo "⚠️ Let op: Development mode is niet veilig voor productie!"
    echo "✔️ Vault is klaar voor gebruik in development mode"
    exit 0
fi

# =============================================================================
# Stap 5: Initialiseer Vault indien nodig
# =============================================================================
if [[ "$VAULT_INITIALIZED" == "false" ]]; then
    echo "🔧 Vault is niet geïnitialiseerd. Start initialisatie..."
    
    # Initialiseer Vault en bewaar de output
    init_output=$(curl -s -X POST -d '{"secret_shares": 1, "secret_threshold": 1}' $VAULT_ADDR/v1/sys/init)
    
    # Controleer of initialisatie succesvol was
    if echo "$init_output" | grep -q "errors"; then
      echo "❌ Fout bij het initialiseren van Vault:"
      echo "$init_output"
      exit 1
    fi
    
    # Bewaar keys en token
    echo "$init_output" | jq -r '.keys_base64[]' > vault_keys.txt
    echo "$init_output" | jq -r '.root_token' > vault_root_token.txt
    
    echo "✔️ Vault geïnitialiseerd"
    echo "📝 Keys opgeslagen in vault_keys.txt"
    echo "🔑 Root token opgeslagen in vault_root_token.txt"
    
    echo "⚠️ BELANGRIJK: Bewaar deze bestanden op een veilige plaats!"
fi

# =============================================================================
# Stap 6: Vault UI Toegang
# =============================================================================
echo
echo "🌐 Vault is nu toegankelijk via:"
echo "📍 UI: https://vault.example.com"
echo "🔑 API: $VAULT_ADDR"
echo
echo "✨ Vault setup voltooid!"

