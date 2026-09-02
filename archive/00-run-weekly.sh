#!/bin/sh

# old script that when added to ~/.local/cron.daily would run the weekly jobs on sundays...
# moved this to a separate timer and unit so that it logs better

day=`date +%w`
if [ "$day" -eq 0 ]; then
    echo "it's sunday, running cron.weekly jobs"
    /usr/bin/run-parts -v "$HOME/.local/cron.weekly"
else
    echo "not sunday, skipping"
    exit 0
fi
