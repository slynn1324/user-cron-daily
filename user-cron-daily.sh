#!/bin/bash

# run $HOME/.local/cron.daily every day at 2am, and $HOME/.local/cron.weekly every sunday at 2am.  jobs are all run linearly so that they
# don't run in parallel potentially impacting resources

daily_dir="$HOME/.local/cron.daily"
weekly_dir="$HOME/.local/cron.weekly"

# all transient units, daily or weekly, are tagged with this same prefix since
# they're all launched by the user-cron-daily service
unit_prefix="user-cron-daily"

# Run every script in $1 (a run-parts style directory) as its own transient
# systemd --user unit, tagged with $2 as the unit name prefix. Units run one
# at a time (via --wait) so jobs never overlap and compete for resources.
run_jobs_in_dir() {
    local dir unit_prefix env_file
    dir="$(realpath "$1")"
    unit_prefix="$2"

    if [ ! -d "$dir" ]; then
        echo "$dir does not exist."
        return 1
    fi

    echo "running jobs in $dir"

    env_file="$dir/env.vars"
    if [ -f "$env_file" ]; then
        echo "will use EnvironmentFile $env_file"
    fi

    run-parts --list "$dir" | while read -r cmd; do

        unit_name="$unit_prefix@$(basename "$cmd")"
        unit_name="${unit_name// /_}" # make sure that there are no spaces in the unit_name, although spaces in the file name won't match the default run-parts pattern

        echo "starting $cmd unit=$unit_name"
        rc=0

        # run a transient unit, collect it out of memory when complete, and wait for it to finish before continuing so we don't try to run all
        # the jobs at the same time
        systemd-run --user --unit="$unit_name" --quiet --collect --wait --property="EnvironmentFile=-$env_file" "$cmd"
        rc=$?

        echo "finished $cmd unit=$unit_name rc=$rc"

        sleep 1 # this just keeps logs more sorted... so steps don't finish at the same time.

    done

    echo "completed jobs in $dir"
}

# daily jobs run every day
run_jobs_in_dir "$daily_dir" "$unit_prefix"

# weekly jobs only run on sundays (date +%w == 0)
day=$(date +%w)
if [ "$day" -eq 0 ]; then
    echo "it's sunday, running cron.weekly jobs"
    run_jobs_in_dir "$weekly_dir" "$unit_prefix"
else
    echo "not sunday, skipping cron.weekly jobs"
fi
