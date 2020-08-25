#!/bin/sh -l

which ansible-playbook

ls ~/compatibility-layer

echo "Hello $1"
time=$(date)
echo "::set-output name=time::$time"
