#!/bin/bash

# A script that expands upon 'run-parts' (and in fact, leverages it) - to execute each part as a transient systemd service unit, 
# primarily so that logs are captured under each service unit independently, in the pattern $unit_prefix@$file_name


if [ -z "$1" ] || [ -z "$2" ] ; then
    echo "Usage: $0 <directory> <unit-prefix>" >&2
    exit 1
fi

dir="$(realpath "$1")"
unit_prefix="$2"

if [ ! -d "$dir" ]; then
    echo "$dir does not exist."
    exit 1
fi


echo "running jobs in $dir"

#for cmd in $(run-parts --list "$dir"); do 

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
