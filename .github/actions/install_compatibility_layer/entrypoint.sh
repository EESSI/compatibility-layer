#!/bin/bash -l

cat << EOF > hosts
[cvmfsstratum0servers]
127.0.0.1 eessi_host_arch=$(uname -m) eessi_host_os=linux
EOF

ansible-playbook -v --connection=local --inventory=hosts -e ansible_python_interpreter=python3 -e gentoo_prefix_path=$1 ${GITHUB_WORKSPACE}/ansible/playbooks/install.yml
