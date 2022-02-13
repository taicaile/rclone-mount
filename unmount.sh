#!/usr/bin/env bash

set -e

function rclone_pids {
    # ps -aux | grep -v grep | grep "rclone mount" | awk '{print $2}'
    ps -aux | pgrep -f "rclone mount"
}

function rclone_mount_paths {
    grep fuse.rclone "/proc/mounts" | awk '{print $2}'
}

# check if rclone mounts process exists
if [ -z "$(rclone_pids)" ]; then
    echo "no rclone mount process found"
else
    # send SIGUP
    echo "send SIGUP signal..."
    rclone_pids | xargs -r -n1 kill -SIGHUP
    # wait 1 second
    echo "wait for 1 second..."
    sleep 1
fi

# send SIGTERM signal
[[ -n $(rclone_pids) ]] && {
    # send SIGTERM
    echo "send SIGTERM signal..."
    rclone_pids | xargs -r -n1 kill -SIGTERM
    # wait for 5 seconds
    echo "wait for 5 second..."
    sleep 5
    # send SIGKILL
    echo "send SIGKILL signal..."
    rclone_pids | xargs -r -n1 kill -SIGKILL
}

# unmount
[[ -n $(rclone_mount_paths) ]] && {
    echo "unmount ..."
    rclone_mount_paths | xargs -r -n1 fusermount -uz
}

echo "unmount done, exit..."
exit 0
