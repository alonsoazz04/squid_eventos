#!/usr/bin/env bash

BOT_TOKEN="$1"
CHAT_ID="$2"
LOGFILE="$3"

tail -F "$LOGFILE" | while read -r line; do
  CLIENT_IP=$(echo "$line" | awk '{print $3}')
  REQUEST=$(echo "$line" | awk '{print $7}')

  if [ -n "$CLIENT_IP" ] && [ -n "$REQUEST" ]; then
    MESSAGE="Evento Squid: cliente ${CLIENT_IP} ${REQUEST}"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d "chat_id=${CHAT_ID}" \
      --data-urlencode "text=${MESSAGE}" > /dev/null
  fi
done
