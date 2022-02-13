#!/usr/bin/env bash

# get the script location
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo "You can copy below to your crontab file, remeber to modify the /path/to/mount"
echo ""
echo "@reboot  $SCRIPT_DIR/mount.sh -d=/path/to/mount > $SCRIPT_DIR/mount.log 2>&1"
