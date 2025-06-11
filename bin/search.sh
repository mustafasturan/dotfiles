#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <engine> <search query>"
  echo "Supported engines: yt, wikipedia, duckduckgo, (default: google)"
  exit 1
fi

ENGINE="$1"
shift
QUERY="$*"

urlencode() {
  local length="${#1}"
  local i char
  for (( i = 0; i < length; i++ )); do
    char="${1:i:1}"
    case "$char" in
      [a-zA-Z0-9.~_-]) printf '%s' "$char" ;;
      ' ') printf '+' ;;
      *) printf '%%%02X' "'$char" ;;
    esac
  done
}

ENCODED_QUERY=$(urlencode "$QUERY")

case "$ENGINE" in
  yt)
    xdg-open "https://www.youtube.com/results?search_query=$ENCODED_QUERY"
    ;;
  wikipedia)
    xdg-open "https://en.wikipedia.org/wiki/Special:Search?search=$ENCODED_QUERY"
    ;;
  duckduckgo)
    xdg-open "https://duckduckgo.com/?q=$ENCODED_QUERY"
    ;;
  *)
    QUERY="$ENGINE $QUERY"
    ENCODED_QUERY=$(urlencode "$QUERY")
    xdg-open "https://www.google.com/search?q=$ENCODED_QUERY"
    ;;
esac
