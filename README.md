# user-cron-daily

A shell script and systemd service and timer files that enable the creation of a ~/.local/cron.daily directory.  The primary advantages are that logs get tagged with transient systemd units and can be accessed via journalctl clearly.

The scripts selected must match the default run-parts rule. On Debian, run-parts will include a file if:

- It consists entirely of upper/lowercase letters, digits, underscores, and hyphens: ^[a-zA-Z0-9_-]+$.
- It is a regular file (not a directory).
- It is executable.

# viewing logs
```
journalctl --user -u user-cron-daily@<script-name> [ --since "1 day ago" ]
```
# running weekly / less than every day

in short, early-exit your script.

e.g.
```
# only run on sundays
day=$(date +%w)
if [ "$day" -ne 0 ]; then
    echo "not sunday, skipping."
    exit 0
fi
```


# install
```
mkdir -p ~/.config/systemd/user
cp user-cron-daily.service ~/.config/systemd/user/
cp user-cron-daily.timer ~/.config/systemd/user/
mkdir -p ~/.local/bin
cp user-cron-daily.sh ~/.local/bin/user-cron-daily

systemctl --user daemon-reload
systemctl --user enable user-cron-daily.timer

mkdir -p ~/.local/cron.daily
touch ~/.local/cron.daily/env.vars
touch ~/.local/cron.daily/user-cron-daily.conf
```


