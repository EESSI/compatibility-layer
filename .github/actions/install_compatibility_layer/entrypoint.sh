#!/bin/sh -l

cat << EOF > hosts
[cvmfsstratum0servers]
127.0.0.1
EOF

ansible-playbook --connection=local --inventory=hosts -e ansible_python_interpreter=python3 -e prefix_location=$1 ${GITHUB_WORKSPACE}/playbooks/install.yml

ls /usr/lmod/lmod
