#!/bin/sh
# pushover.sh — Send a push notification via the Pushover API.
# Portable POSIX shell. Requires curl or wget.
#
# Environment:
#   PUSHOVER_USER_KEY   — Your Pushover user key (required)
#   PUSHOVER_API_TOKEN  — Your Pushover app API token (required)
#
# Usage:
#   pushover.sh -m "Hello world"
#   pushover.sh -m "Alert!" -t "Title" -p 1 -s "siren"
#
# Exit codes:
#   0  success
#   1  missing dependency / env var / argument
#   2  API request failed

set -e

# ── Defaults ──────────────────────────────────────────────────────────────────
TITLE="Claude Notification"
PRIORITY=0
SOUND=""
URL=""
URL_TITLE=""
DEVICE=""
MESSAGE=""

# ── Parse arguments ───────────────────────────────────────────────────────────
while getopts "m:t:p:s:u:n:d:" opt; do
  case "$opt" in
    m) MESSAGE="$OPTARG" ;;
    t) TITLE="$OPTARG" ;;
    p) PRIORITY="$OPTARG" ;;
    s) SOUND="$OPTARG" ;;
    u) URL="$OPTARG" ;;
    n) URL_TITLE="$OPTARG" ;;
    d) DEVICE="$OPTARG" ;;
    *) echo "Usage: $0 -m MESSAGE [-t TITLE] [-p PRIORITY] [-s SOUND] [-u URL] [-n URL_TITLE] [-d DEVICE]" >&2; exit 1 ;;
  esac
done

# ── Validate ──────────────────────────────────────────────────────────────────
if [ -z "$PUSHOVER_USER_KEY" ]; then
  echo "Error: PUSHOVER_USER_KEY is not set." >&2
  exit 1
fi

if [ -z "$PUSHOVER_API_TOKEN" ]; then
  echo "Error: PUSHOVER_API_TOKEN is not set." >&2
  exit 1
fi

if [ -z "$MESSAGE" ]; then
  echo "Error: Message (-m) is required." >&2
  exit 1
fi

# ── Detect HTTP client ───────────────────────────────────────────────────────
if command -v curl >/dev/null 2>&1; then
  HTTP_CLIENT="curl"
elif command -v wget >/dev/null 2>&1; then
  HTTP_CLIENT="wget"
else
  echo "Error: Neither curl nor wget found. Install one to use this script." >&2
  exit 1
fi

# ── Build POST data ──────────────────────────────────────────────────────────
API_URL="https://api.pushover.net/1/messages.json"

# For emergency priority, Pushover requires retry and expire parameters
RETRY=""
EXPIRE=""
if [ "$PRIORITY" = "2" ]; then
  RETRY="60"
  EXPIRE="3600"
fi

# ── Send request ─────────────────────────────────────────────────────────────
if [ "$HTTP_CLIENT" = "curl" ]; then
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    --form-string "token=$PUSHOVER_API_TOKEN" \
    --form-string "user=$PUSHOVER_USER_KEY" \
    --form-string "message=$MESSAGE" \
    --form-string "title=$TITLE" \
    --form-string "priority=$PRIORITY" \
    ${SOUND:+--form-string "sound=$SOUND"} \
    ${URL:+--form-string "url=$URL"} \
    ${URL_TITLE:+--form-string "url_title=$URL_TITLE"} \
    ${DEVICE:+--form-string "device=$DEVICE"} \
    ${RETRY:+--form-string "retry=$RETRY"} \
    ${EXPIRE:+--form-string "expire=$EXPIRE"} \
    "$API_URL" 2>&1)

  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | sed '$d')

else
  # wget fallback — build URL-encoded POST body
  urlencode() {
    printf '%s' "$1" | od -An -tx1 | tr ' ' '%' | tr -d '\n' | sed 's/%0a$//;s/%/%/g'
  }

  POST_DATA="token=$(urlencode "$PUSHOVER_API_TOKEN")"
  POST_DATA="$POST_DATA&user=$(urlencode "$PUSHOVER_USER_KEY")"
  POST_DATA="$POST_DATA&message=$(urlencode "$MESSAGE")"
  POST_DATA="$POST_DATA&title=$(urlencode "$TITLE")"
  POST_DATA="$POST_DATA&priority=$PRIORITY"
  [ -n "$SOUND" ]     && POST_DATA="$POST_DATA&sound=$(urlencode "$SOUND")"
  [ -n "$URL" ]       && POST_DATA="$POST_DATA&url=$(urlencode "$URL")"
  [ -n "$URL_TITLE" ] && POST_DATA="$POST_DATA&url_title=$(urlencode "$URL_TITLE")"
  [ -n "$DEVICE" ]    && POST_DATA="$POST_DATA&device=$(urlencode "$DEVICE")"
  [ -n "$RETRY" ]     && POST_DATA="$POST_DATA&retry=$RETRY"
  [ -n "$EXPIRE" ]    && POST_DATA="$POST_DATA&expire=$EXPIRE"

  BODY=$(wget -qO- --post-data="$POST_DATA" "$API_URL" 2>&1) || true
  # wget doesn't easily give HTTP status; check response body
  HTTP_CODE="unknown"
fi

# ── Report result ────────────────────────────────────────────────────────────
case "$BODY" in
  *'"status":1'*)
    echo "OK: Notification sent successfully."
    echo "$BODY"
    exit 0
    ;;
  *)
    echo "Error: Pushover API returned an error." >&2
    echo "HTTP status: $HTTP_CODE" >&2
    echo "Response: $BODY" >&2
    exit 2
    ;;
esac
