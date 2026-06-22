#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../android"
if [[ ! -f key.properties ]]; then
  echo "android/key.properties does not exist." >&2
  exit 1
fi

store_file=$(sed -n 's/^storeFile=//p' key.properties)
store_password=$(sed -n 's/^storePassword=//p' key.properties)
key_alias=$(sed -n 's/^keyAlias=//p' key.properties)
keytool -list -v \
  -keystore "app/$store_file" \
  -storepass "$store_password" \
  -alias "$key_alias" | sed -n 's/^[[:space:]]*SHA1: /SHA-1: /p'
