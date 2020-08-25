#!/bin/sh -l

ansible-playbook --connection=local --inventory=127.0.0.1, -e prefix_location=/tmp/gentoo ${GITHUB_WORKSPACE}/playbooks/install.yml

echo "Hello $1"
time=$(date)
echo "::set-output name=time::$time"
