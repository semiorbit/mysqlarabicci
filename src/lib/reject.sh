#!/bin/bash
set -euo pipefail

# ----------------------------
# reject.sh
# ----------------------------
# Removes Arabic utf8 collation injected by mysqlarabicci
# Idempotent: safe to run multiple times
# ----------------------------

reject() {
  local CONF="/etc/mysqlarabicci/mysqlarabicci.conf"

  # load config
  if [ ! -f "$CONF" ]; then
    echo "Config not found: $CONF" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "$CONF"

  # sanity check
  [ -f "$INDEX_XML" ] || {
    echo "Index.xml not found: $INDEX_XML" >&2
    exit 1
  }

  # nothing to do?
  if ! grep -q "$MARKER" "$INDEX_XML"; then
    return 0
  fi

  TMP="$(mktemp)"

  # remove block between markers
  awk '
    /mysqlarabicci BEGIN/ { skip=1; next }
    /mysqlarabicci END/   { skip=0; next }
    !skip { print }
  ' "$INDEX_XML" > "$TMP"

  # atomic replace
  install -m 644 "$TMP" "$INDEX_XML"
  rm -f "$TMP"
}
