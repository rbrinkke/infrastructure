#!/bin/bash

# Variabelen
SSH_PORT=22
LOGFILE="$HOME/ngrok_ssh.log"
NGROK_CMD="ngrok tcp $SSH_PORT"

echo "===== Start Ngrok voor SSH ====="

# Start Ngrok
$NGROK_CMD --log=stdout > "$LOGFILE" 2>&1 &
NGROK_PID=$!

# Wacht een paar seconden om Ngrok op te starten
sleep 5

# Controleer of Ngrok draait
if ! ps -p $NGROK_PID > /dev/null; then
    echo "ERROR: Ngrok kon niet worden gestart. Controleer het logbestand: $LOGFILE"
    exit 1
fi

# Haal de publiek toegankelijke URL op
NGROK_URL=$(grep -o "tcp://[0-9.]*:[0-9]*" "$LOGFILE" | head -n 1)
if [ -z "$NGROK_URL" ]; then
    echo "ERROR: Kan geen Ngrok URL vinden. Controleer het logbestand: $LOGFILE"
    kill $NGROK_PID
    exit 1
fi

# Toon de URL
echo "Ngrok is gestart! Publieke SSH-tunnel: $NGROK_URL"
echo "Gebruik deze URL voor GitHub Actions: $NGROK_URL"

# Bewaar de PID en URL in een bestand
echo $NGROK_PID > "$HOME/ngrok_pid"
echo $NGROK_URL > "$HOME/ngrok_url"

echo "===== Ngrok voor SSH gestart ====="

