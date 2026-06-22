#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f .release.env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .release.env
  set +a
fi

: "${GOOGLE_WEB_CLIENT_ID:=2933396048-c2rsa8a34bkbrgbscmr1kuqqb69fvh5c.apps.googleusercontent.com}"
: "${API_BASE_URL:?Set API_BASE_URL in mobile/.release.env}"

if [[ "$API_BASE_URL" != https://script.google.com/macros/s/*/exec ]]; then
  echo "API_BASE_URL must be an Apps Script /exec URL." >&2
  exit 1
fi

flutter build apk --release \
  --dart-define="GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID" \
  --dart-define="API_BASE_URL=$API_BASE_URL"

echo "APK: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
