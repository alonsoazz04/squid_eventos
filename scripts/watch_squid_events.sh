#!/usr/bin/env bash

BOT_TOKEN="$1"
CHAT_ID="$2"
LOGFILE="$3"

tail -F "$LOGFILE" | while read -r line; do
  CLIENT_IP=$(echo "$line" | awk '{print $3}')
  REQUEST=$(echo "$line" | sed -n 's/.*"\(.*\)".*/\1/p')

  if [ -n "$CLIENT_IP" ] && [ -n "$REQUEST" ]; then
    MESSAGE="Evento Squid: cliente ${CLIENT_IP} -> ${REQUEST}"
    ~/squid-demo/scripts/send_telegram.sh "$BOT_TOKEN" "$CHAT_ID" "$MESSAGE"
  fi
done
