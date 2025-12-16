#!/bin/bash
set -euo pipefail

# ----------------------------
# mysqlarabicci installer
# ----------------------------
#  Detect running MySQL version (via MySQL itself)
#
#  Decide which charset layout is used (legacy vs versioned)
#
#  Ask the user to CONFIRM
#
#  Install files into system locations
#
#  Write config
#
#  Write systemd units with exact path
#
#  Enable watcher
# ----------------------------


echo "mysqlarabicci installer"
echo "-----------------------"

# must be root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# check mysql client
if ! command -v mysql >/dev/null 2>&1; then
  echo "mysql client not found"
  exit 1
fi

# detect running mysql version
MYSQL_VERSION="$(mysql -Nse 'SELECT VERSION();' 2>/dev/null || true)"

if [ -z "$MYSQL_VERSION" ]; then
  echo "MySQL is not running or not accessible"
  exit 1
fi

MYSQL_MM="${MYSQL_VERSION%.*}"

echo "Detected MySQL version: $MYSQL_VERSION"

# detect charset layout
CANDIDATE_VERSIONED="/usr/share/mysql-$MYSQL_MM/charsets/Index.xml"
CANDIDATE_LEGACY="/usr/share/mysql/charsets/Index.xml"

if [ -f "$CANDIDATE_VERSIONED" ]; then
  INDEX_XML="$CANDIDATE_VERSIONED"
  LAYOUT="versioned"
elif [ -f "$CANDIDATE_LEGACY" ]; then
  INDEX_XML="$CANDIDATE_LEGACY"
  LAYOUT="legacy"
else
  echo "Could not find MySQL charset Index.xml"
  echo "Checked:"
  echo "  $CANDIDATE_VERSIONED"
  echo "  $CANDIDATE_LEGACY"
  exit 1
fi

echo "Detected charset layout: $LAYOUT"
echo "Index.xml path:"
echo "  $INDEX_XML"
echo

read -rp "Is this correct? [y/N]: " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Installation aborted"
  exit 1
fi

# ----------------------------
# install directories
# ----------------------------

echo "Installing files..."

install -d /usr/local/bin
install -d /usr/local/lib/mysqlarabicci
install -d /etc/mysqlarabicci
install -d /etc/systemd/system

# ----------------------------
# install binaries and libs
# ----------------------------

install -m 755 src/bin/mysqlarabicci /usr/local/bin/mysqlarabicci

install -m 755 src/lib/detect_mysql.sh /usr/local/lib/mysqlarabicci/detect_mysql.sh
install -m 755 src/lib/inject.sh        /usr/local/lib/mysqlarabicci/inject.sh
install -m 755 src/lib/reject.sh        /usr/local/lib/mysqlarabicci/reject.sh

install -m 644 src/snippets/utf8_arabic_ci.xml /usr/local/lib/mysqlarabicci/utf8_arabic_ci.xml

# ----------------------------
# write config
# ----------------------------

cat > /etc/mysqlarabicci/mysqlarabicci.conf <<EOF
# mysqlarabicci configuration

MYSQL_VERSION=$MYSQL_MM
INDEX_XML=$INDEX_XML
MYSQL_SERVICE=mysqld

MARKER=utf8_arabic_ci
SNIPPET=/usr/local/lib/mysqlarabicci/utf8_arabic_ci.xml
EOF

# ----------------------------
# install systemd units
# ----------------------------

cat > /etc/systemd/system/mysqlarabicci.service <<EOF
[Service]
Type=oneshot
ExecStart=/usr/local/bin/mysqlarabicci --inject
EOF

cat > /etc/systemd/system/mysqlarabicci.path <<EOF
[Path]
PathChanged=$INDEX_XML

[Install]
WantedBy=multi-user.target
EOF

# ----------------------------
# enable systemd watcher
# ----------------------------

systemctl daemon-reload
systemctl enable --now mysqlarabicci.path

echo
echo "Installation complete."
echo "You can now use: mysqlarabicci --help"
