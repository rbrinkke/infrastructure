#!/bin/bash

# Variabelen
AUTHTOKEN="2pi70K8gBbBgJOpS3Dgs3KacsiC_3b1wx34n6FWdHdFCxpHzo" # Vervang met je daadwerkelijke token
NGROK_CONFIG_OLD="$HOME/.ngrok2/ngrok.yml"
NGROK_CONFIG_NEW="$HOME/.config/ngrok/ngrok.yml"
LOGFILE="$HOME/ngrok_fix.log"

echo "===== Ngrok Auth Fix Script =====" | tee "$LOGFILE"

# Stap 1: Controleer Ngrok-versie
echo "1. Controleer Ngrok-versie..." | tee -a "$LOGFILE"
ngrok_version=$(ngrok version | grep -oP "(?<=ngrok version )\S+")
if [[ -z $ngrok_version ]]; then
    echo "ERROR: Ngrok niet geïnstalleerd. Controleer installatie." | tee -a "$LOGFILE"
    exit 1
fi
echo "   - Geïnstalleerde Ngrok-versie: $ngrok_version" | tee -a "$LOGFILE"

# Stap 2: Controleer en stel authtoken in
echo "2. Instellen van authtoken..." | tee -a "$LOGFILE"
ngrok authtoken "$AUTHTOKEN" >> "$LOGFILE" 2>&1
if [[ $? -ne 0 ]]; then
    echo "ERROR: Authtoken instellen mislukt." | tee -a "$LOGFILE"
    exit 1
fi
echo "   - Authtoken succesvol ingesteld." | tee -a "$LOGFILE"

# Stap 3: Verplaats legacy configuratie (indien aanwezig)
if [[ -f "$NGROK_CONFIG_OLD" ]]; then
    echo "3. Legacy configuratie gevonden. Verplaatsen naar nieuwe locatie..." | tee -a "$LOGFILE"
    mkdir -p "$(dirname $NGROK_CONFIG_NEW)" >> "$LOGFILE" 2>&1
    mv "$NGROK_CONFIG_OLD" "$NGROK_CONFIG_NEW" >> "$LOGFILE" 2>&1
    if [[ $? -eq 0 ]]; then
        echo "   - Legacy configuratie succesvol verplaatst." | tee -a "$LOGFILE"
    else
        echo "ERROR: Verplaatsen van legacy configuratie mislukt." | tee -a "$LOGFILE"
        exit 1
    fi
else
    echo "   - Geen legacy configuratie gevonden." | tee -a "$LOGFILE"
fi

# Stap 4: Start Ngrok handmatig en controleer
echo "4. Starten van Ngrok voor SSH..." | tee -a "$LOGFILE"
ngrok tcp 22 >> "$LOGFILE" 2>&1 &
NGROK_PID=$!
sleep 5

# Controleer of Ngrok draait
if ps -p $NGROK_PID > /dev/null; then
    echo "   - Ngrok succesvol gestart." | tee -a "$LOGFILE"
    kill $NGROK_PID
else
    echo "ERROR: Ngrok kon niet worden gestart. Controleer $LOGFILE voor details." | tee -a "$LOGFILE"
    exit 1
fi

echo "===== Ngrok Auth Fix Script Completed =====" | tee -a "$LOGFILE"

