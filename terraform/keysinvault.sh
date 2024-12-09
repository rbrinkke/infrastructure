#!/bin/bash

# Error handling
set -e
handle_error() {
  echo "❌ Fout op regel $1"
  exit 1
}
trap 'handle_error $LINENO' ERR

# Controleer Vault environment
if [ -z "$VAULT_ADDR" ] || [ -z "$VAULT_TOKEN" ]; then
    echo "❌ Stel eerst VAULT_ADDR en VAULT_TOKEN in"
    exit 1
fi

# Controleer verbinding met Vault
if ! vault status >/dev/null 2>&1; then
    echo "❌ Geen verbinding met Vault op $VAULT_ADDR"
    exit 1
fi

# Functie om een sterk wachtwoord te genereren
generate_password() {
    openssl rand -base64 24 | tr -d '/+=' | cut -c1-24
}

# Functie om bestaande secrets op te halen
get_existing_secrets() {
    if vault kv get -format=json secret/terraform >/dev/null 2>&1; then
        vault kv get -format=json secret/terraform | jq -r '.data.data | keys[]'
    else
        echo ""
    fi
}

# Lijst van alle benodigde secrets
declare -A required_secrets=(
    ["traefik_network_name"]="Naam voor Traefik netwerk (default: traefik_network)"
    ["monitoring_network_name"]="Naam voor monitoring netwerk (default: monitoring_network)"
    ["auth_network_name"]="Naam voor auth netwerk (default: auth_network)"
    ["logging_network_name"]="Naam voor logging netwerk (default: logging_network)"
    ["postgres_user"]="PostgreSQL gebruikersnaam (default: keycloak)"
    ["keycloak_admin"]="Keycloak admin gebruikersnaam (default: admin)"
    ["minio_root_user"]="MinIO root gebruikersnaam (default: admin)"
    ["couchdb_user"]="CouchDB admin gebruikersnaam (default: admin)"
    ["grafana_admin_user"]="Grafana admin gebruikersnaam (default: admin)"
    ["backup_retention_days"]="Aantal dagen om backups te bewaren (default: 30)"
    ["grafana_admin_password"]="GENERATE"
    ["postgres_password"]="GENERATE"
    ["keycloak_admin_password"]="GENERATE"
    ["redis_password"]="GENERATE"
    ["minio_root_password"]="GENERATE"
    ["couchdb_password"]="GENERATE"
    ["couchdb_secret"]="GENERATE"
    ["backup_password"]="GENERATE"
    ["s3_backup_bucket"]="Naam van de S3 bucket voor backups"
    ["aws_access_key"]="AWS Access Key voor S3 backups"
    ["aws_secret_key"]="AWS Secret Key voor S3 backups"
)

# Haal bestaande secrets op
existing_secrets=$(get_existing_secrets)

# Tijdelijk bestand voor nieuwe secrets
TMPFILE=$(mktemp)
echo "{" > "$TMPFILE"
first_entry=true

# Loop door alle benodigde secrets
for secret in "${!required_secrets[@]}"; do
    # Skip als secret al bestaat
    if echo "$existing_secrets" | grep -q "^$secret$"; then
        continue
    fi

    description="${required_secrets[$secret]}"
    value=""

    if [ "$description" == "GENERATE" ]; then
        # Genereer een sterk wachtwoord voor geheime waarden
        value=$(generate_password)
        echo "🔐 Gegenereerd wachtwoord voor $secret"
    else
        # Vraag waarde voor niet-geheime configuratie
        default_value=""
        if [[ $description =~ "default: "* ]]; then
            default_value=$(echo "$description" | sed 's/.*default: \([^ )]*\).*/\1/')
        fi

        # Vraag de waarde, gebruik default indien enter wordt gedrukt
        read -p "📝 $description: " input_value
        value=${input_value:-$default_value}
    fi

    # Voeg toe aan JSON
    if [ "$first_entry" = true ]; then
        first_entry=false
    else
        echo "," >> "$TMPFILE"
    fi
    echo "  \"$secret\": \"$value\"" >> "$TMPFILE"
done

echo "}" >> "$TMPFILE"

# Update alleen als er nieuwe secrets zijn
if [ "$first_entry" = false ]; then
    if ! vault kv get secret/terraform >/dev/null 2>&1; then
        # Eerste keer toevoegen
        vault kv put secret/terraform @"$TMPFILE"
    else
        # Patch bestaande secrets
        vault kv patch secret/terraform @"$TMPFILE"
    fi
    echo "✅ Nieuwe secrets zijn toegevoegd aan Vault"
else
    echo "✅ Alle benodigde secrets bestaan al in Vault"
fi

# Ruim tijdelijk bestand op
rm "$TMPFILE"

# Toon overzicht van alle secrets (zonder waarden)
echo
echo "🔍 Huidige secrets in Vault:"
vault kv get -format=yaml secret/terraform | grep -v ': '
