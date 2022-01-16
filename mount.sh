#!/usr/bin/env bash

set -e

usage="$(basename "$0") -d/--drives-mount-dir=/path/to/drive, to mount all remotes configed in rclone

where:

-h  show this help text
-d/--drives-base-dir  set the remotes mount base directory

or set the drives-base-dir via envrionment variables:
export DRIVES_BASE_DIR=/path/to/drive
"

function parser {
    for i in "$@"; do
        case $i in
        -d=* | --drives-base-dir=*)
            DRIVES_BASE_DIR="${i#*=}"
            shift # past argument=value
            ;;
        -h)
            echo "$usage"
            exit 1
            ;;
        *)
            echo "Unknown option $i"
            echo "$usage"
            exit 1
            ;;
        esac
    done
}

function assert_installed {
    # if ! apt -qq list "$1" --installed 2>/dev/null | grep -qE "(installed|upgradeable)";  then
    if ! command -v "$1" &>/dev/null; then
        echo " $1 is not installed, please install it, exit..."
        exit 1
    fi
}

function assert_dir_exists {
    if [ ! -d "$1" ]; then
        echo " $1 does not exist, exit..."
        exit 1
    fi
}

function create_dir {
    # create dir if not exists, make sure the parente exists
    [ -d "$1" ] || mkdir -p "$1"
}

function is_mount {
    path=$(readlink -f "$1")
    grep -q "$path" /proc/mounts
}

parser "$@"

# check required parameters
if [[ -z "${DRIVES_BASE_DIR}" ]]; then
    echo "$usage"
    exit 1
else
    DRIVES_BASE_DIR="$(realpath "${DRIVES_BASE_DIR}")"
fi

# check drives-base-dir exists
assert_dir_exists "$DRIVES_BASE_DIR"

# check if rclone installed
PRE_INSTALLS=("rclone")
for program in "${PRE_INSTALLS[@]}"; do
    assert_installed "$program"
done

DRIVES_LOG_DIR="$DRIVES_BASE_DIR/logs"
DRIVES_CACHE_DIR="$DRIVES_BASE_DIR/.cache"
DRIVES_MOUNT_DIR="$DRIVES_BASE_DIR/drives"

# create directories for logs, cache
for path in "$DRIVES_LOG_DIR" "$DRIVES_CACHE_DIR" "$DRIVES_MOUNT_DIR"; do
    create_dir "$path"
done

while read -r REMOTE; do
    REMOTE_NAME="${REMOTE%?}"
    MOUNTPOINT="$DRIVES_MOUNT_DIR/$REMOTE_NAME"
    # no write permission, and mounted
    if [ ! -w "$MOUNTPOINT" ] && is_mount "$MOUNTPOINT"; then
        # try to unmount
        fusermount -uz "$MOUNTPOINT"
    fi
    create_dir "$MOUNTPOINT"

    if is_mount "$MOUNTPOINT"; then
        echo "$MOUNTPOINT is already mounted"
    else
        rclone mount "$REMOTE" "$MOUNTPOINT" \
            --config /home/li/.config/rclone/rclone.conf \
            --vfs-cache-mode full \
            --log-file "$DRIVES_LOG_DIR/$REMOTE_NAME.log" \
            --cache-dir "$DRIVES_CACHE_DIR" \
            --daemon
        echo "$REMOTE is mounted at: $MOUNTPOINT"
    fi
done <<EOF
$(rclone listremotes)
EOF
