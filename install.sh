#!/bin/bash
set -euo pipefail

echo "mysqlarabicci installer"
echo "-----------------------"
echo "SEMIORBIT MYSQL UTF8 ARABIC CI COLLATION"
echo "-----------------------"
echo "utf8_arabic_ci [1029] collation will help ignoring Arabic (Hamza & Tashkil) on applied field in MySQL"
echo "-----------------------"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# basic sanity checks
command -v mysql >/dev/null 2>&1 || {
  echo "mysql client not found"
  exit 1
}

# run real installer
bash src/installer/install.sh
