# GOOGLE DRIVE MOUNT

```bash
# to mount all remotes
./mount.sh -d=/path/to/mount

# to unmount all remotes
./unmount.sh
```

To run on reboot,

```bash
# add @reboot cron job,
crontab -e
# add following,
@reboot  /home/jobs/mount.sh -d=/path/to/mount > /home/jobs/mount.log 2>&1
```
