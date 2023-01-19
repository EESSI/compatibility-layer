#!/bin/bash

# Launch the compatibility layer installation using Ansible inside an Apptainer container.
# A location for temporary directories has to be passed to the script, and the resulting
# installation will end up in the subdirectory "cvmfs" (which is bind mounted as /cvmfs into the container).

CONTAINER=docker://ghcr.io/eessi/bootstrap-prefix:debian11

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path for temporary directories>" >&2
    exit 1
fi

EESSI_TMPDIR=$1
# Make sure specified temporary directory exists
mkdir -p $EESSI_TMPDIR
echo "Using $EESSI_TMPDIR as parent for temporary directories..."

# Create temporary directories
mkdir -p ${EESSI_TMPDIR}/cvmfs
mkdir -p ${EESSI_TMPDIR}/compatibility-layer
mkdir -p ${EESSI_TMPDIR}/home

# Set up paths and mount points for Apptainer
export APPTAINER_CACHEDIR=${EESSI_TMPDIR}/apptainer_cache
export APPTAINER_BIND="${EESSI_TMPDIR}/cvmfs:/cvmfs,${EESSI_TMPDIR}/compatibility-layer:/compatibility-layer"
export APPTAINER_HOME="${EESSI_TMPDIR}/home:/home/${USER}"

# Finally, run Ansible inside the container to do the actual installation
ANSIBLE_COMMAND="ansible-playbook -e eessi_host_os=linux -e eessi_host_arch=$(uname -m) /compatibility-layer/ansible/playbooks/install.yml"
apptainer shell ${CONTAINER} <<EOF
git clone https://github.com/EESSI/compatibility-layer /compatibility-layer
# The Gentoo Prefix bootstrap script will complain if $LD_LIBRARY_PATH is set
unset LD_LIBRARY_PATH
${ANSIBLE_COMMAND}
EOF
