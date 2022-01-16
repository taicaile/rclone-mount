#!/usr/bin/env bash

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
    # send sigup
    echo "send SIGUP signal..."
    rclone_pids | xargs -r -n1 kill -SIGHUP "$1"
    # wait 1 second
    echo "wait for 1 second..."
    sleep 1
fi

# unmount
[[ -n $(rclone_mount_paths) ]] && {
    echo "unmount ..."
    rclone_mount_paths | xargs -r -n1 fusermount -uz "$1"
}

# send SIGTERM signal
[[ -n $(rclone_pids) ]] && {
    # send SIGTERM
    rclone_pids | xargs -r -n1 kill -SIGTERM "$1"
    # wait for 5 seconds
    sleep 5
    # send SIGKILL
    rclone_pids | xargs -r -n1 kill -SIGKILL "$1"
}

exit 0
