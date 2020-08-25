#!/bin/sh -l

ansible-playbook --connection=local --inventory=127.0.0.1, compatibility-layer/playbooks/install.yml

ls ~/compatibility-layer

echo "Hello $1"
time=$(date)
echo "::set-output name=time::$time"
