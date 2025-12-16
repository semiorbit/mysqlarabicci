#!/bin/bash
set -euo pipefail

# ----------------------------
# detect_mysql.sh
# ----------------------------
# Outputs:
#   MYSQL_VERSION (major.minor)
#   INDEX_XML (absolute path)
# ----------------------------
#  Ask running MySQL for its version
#
#  Decide which charset layout is used
#
#  Output shell-safe values for callers
#
#  Fail loudly if nothing matches
# ----------------------------

# check mysql client
if ! command -v mysql >/dev/null 2>&1; then
  echo "mysql client not found" >&2
  exit 1
fi

# ask running mysql
MYSQL_FULL_VERSION="$(mysql -Nse 'SELECT VERSION();' 2>/dev/null || true)"

if [ -z "$MYSQL_FULL_VERSION" ]; then
  echo "MySQL is not running or not accessible" >&2
  exit 1
fi

MYSQL_VERSION="${MYSQL_FULL_VERSION%.*}"

# probe filesystem layouts
CANDIDATE_VERSIONED="/usr/share/mysql-$MYSQL_VERSION/charsets/Index.xml"
CANDIDATE_LEGACY="/usr/share/mysql/charsets/Index.xml"

if [ -f "$CANDIDATE_VERSIONED" ]; then
  INDEX_XML="$CANDIDATE_VERSIONED"
elif [ -f "$CANDIDATE_LEGACY" ]; then
  INDEX_XML="$CANDIDATE_LEGACY"
else
  echo "Could not locate MySQL charset Index.xml" >&2
  exit 1
fi

# output shell-safe assignments
cat <<EOF
MYSQL_VERSION=$MYSQL_VERSION
INDEX_XML=$INDEX_XML
EOF
