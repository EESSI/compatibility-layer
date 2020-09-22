#!/bin/bash -l

cat << EOF > hosts
[cvmfsstratum0servers]
127.0.0.1
EOF

ansible-playbook --connection=local --inventory=hosts -e ansible_python_interpreter=python3 -e gentoo_prefix_path=$1 ${GITHUB_WORKSPACE}/ansible/playbooks/install.yml

# A successful installation should at least have Lmod and archspec,
# so let's  check if we can use them.
source $1/usr/lmod/lmod/init/profile
module avail
$1/usr/bin/archspec cpu
