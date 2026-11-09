#!/bin/sh
set -eu
: "${WEB_USER:?Set WEB_USER in .env}"
: "${WEB_PASSWORD:?Set WEB_PASSWORD in .env}"
if [ "${#WEB_PASSWORD}" -lt 24 ] || [ "$WEB_PASSWORD" = "REPLACE_THIS_WITH_A_UNIQUE_32_CHARACTER_SECRET" ]; then
  echo "WEB_PASSWORD must be a unique secret of at least 24 characters; edit .env first." >&2
  exit 1
fi
install -d -m 0755 /run/nginx
htpasswd -Bbn "$WEB_USER" "$WEB_PASSWORD" > /run/nginx/htpasswd
chmod 0644 /run/nginx/htpasswd
exec nginx -g 'daemon off;'
