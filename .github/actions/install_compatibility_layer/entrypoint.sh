#!/bin/sh -l

echo "[cvmfsstratum0servers]\n127.0.0.1" > hosts
ansible-playbook --connection=local --inventory=hosts -e prefix_location=/tmp/gentoo ${GITHUB_WORKSPACE}/playbooks/install.yml

echo "Hello $1"
time=$(date)
echo "::set-output name=time::$time"
