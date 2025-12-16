#!/bin/bash
set -euo pipefail

# ----------------------------
# inject.sh
# ----------------------------
# Injects Arabic utf8 collation into MySQL Index.xml
# Idempotent: safe to run multiple times
# ----------------------------

inject() {
  local CONF="/etc/mysqlarabicci/mysqlarabicci.conf"

  # load config
  if [ ! -f "$CONF" ]; then
    echo "Config not found: $CONF" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "$CONF"

  # sanity checks
  [ -f "$INDEX_XML" ] || {
    echo "Index.xml not found: $INDEX_XML" >&2
    exit 1
  }

  [ -f "$SNIPPET" ] || {
    echo "Snippet not found: $SNIPPET" >&2
    exit 1
  }

  # already injected?
  if grep -q "$MARKER" "$INDEX_XML"; then
    return 0
  fi

  # ensure utf8 charset block exists
  if ! grep -q '<charset name="utf8">' "$INDEX_XML"; then
    echo "utf8 charset block not found in Index.xml" >&2
    exit 1
  fi

  TMP="$(mktemp)"

  # inject snippet before closing </charset> of utf8
  awk -v snip="$SNIPPET" '
    BEGIN { in_utf8=0; injected=0 }
    /<charset name="utf8">/ {
      in_utf8=1
    }
    in_utf8 && /<\/charset>/ && !injected {
      while ((getline line < snip) > 0) {
        print line
      }
      injected=1
    }
    {
      print
    }
  ' "$INDEX_XML" > "$TMP"

  # atomic replace
  install -m 644 "$TMP" "$INDEX_XML"
  rm -f "$TMP"
}
