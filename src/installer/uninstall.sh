#!/bin/bash
set -euo pipefail

echo "mysqlarabicci uninstaller"
echo "------------------------"

# must be root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

CONF="/etc/mysqlarabicci/mysqlarabicci.conf"
BIN="/usr/local/bin/mysqlarabicci"
LIB="/usr/local/lib/mysqlarabicci"
SYSTEMD_SERVICE="/etc/systemd/system/mysqlarabicci.service"
SYSTEMD_PATH="/etc/systemd/system/mysqlarabicci.path"

# attempt to reject injected collation if config exists
if [ -f "$CONF" ] && [ -x "$BIN" ]; then
  echo "Checking for injected collation..."

  if "$BIN" --check >/dev/null 2>&1; then
    echo "Removing injected collation..."
    "$BIN" --reject || true
    echo "NOTE: MySQL was NOT restarted."
  else
    echo "No injected collation found."
  fi
fi

echo
echo "Disabling systemd units..."

# stop and disable path unit if present
if [ -f "$SYSTEMD_PATH" ]; then
  systemctl disable --now mysqlarabicci.path 2>/dev/null || true
  rm -f "$SYSTEMD_PATH"
fi

# remove service unit
rm -f "$SYSTEMD_SERVICE"

systemctl daemon-reload

echo
echo "Removing installed files..."

rm -f "$BIN"
rm -rf "$LIB"
rm -rf /etc/mysqlarabicci

echo
echo "Uninstall complete."
echo "You may restart MySQL manually if needed."
