#!/bin/bash
#
# Launch the compatibility layer installation using Ansible inside an Apptainer container.
# This can be run on any machine which has Apptainer installed, no special privileges are required.
#

ARCH=
CONTAINER=docker://ghcr.io/eessi/bootstrap-prefix:debian11
REPOSITORY="pilot.eessi-hpc.org"
STORAGE=
VERSION=

display_help() {
  echo "usage: $0 [OPTIONS]"
  echo " OPTIONS:"
  echo "  -a | --arch ARCH       - architecture to build a compatibility layer for"
  echo "                           [default/required: current host's architecture]"
  echo "  -c | --container IMG   - image file or URL defining the container to use"
  echo "                           [default: ${CONTAINER}"
  echo "  -g | --storage DIR     - directory space on host machine (used for"
  echo "                           temporary data) [default: 1. TMPDIR, 2. /tmp]"
  echo "  -h | --help            - display this usage information"
  echo "  -r | --repository REPO - CVMFS repository name [default: ${REPOSITORY}]"
  echo "  -v | --version VERSION - override the EESSI stack version set in Ansible's"
  echo "                           defaults/main.yml file [default: None]"
  echo
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--arch)
      ARCH="$2"
      shift 2
      ;;
    -c|--container)
      CONTAINER="$2"
      shift 2
      ;;
    -g|--storage)
      STORAGE="$2"
      shift 2
      ;;
    -h|--help)
      display_help
      exit 0
      ;;
    -r|--repository)
      REPOSITORY="$2"
      shift 2
      ;;
    -v|--version)
      VERSION="$2"
      shift 2
      ;;
    -*|--*)
      fatal_error "Unknown option: $1" "${CMDLINE_ARG_UNKNOWN_EXITCODE}"
      ;;
    *)  # No more options
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"

# We assume that this script is located in a directory containing a full checkout of the git repo,
# we verify this by checking for the existance oif the Ansible playbook.
SCRIPT_DIR=$(dirname $(realpath $0))
if [ ! -f "${SCRIPT_DIR}/ansible/playbooks/install.yml" ]; then
    echo "Ansible playbook install.yml cannot be found!"
    echo "Make sure to run this script from a directory containing a the compatibility-layer git repository."
    exit 1
fi

# Check if the target architecture is set to the architecture of the current host,
# as that's the only thing that's currently supported by this script
HOST_ARCH=$(uname -m)
if [[ ! -z ${ARCH} ]] && [[ "${ARCH}" != "${HOST_ARCH}" ]]; then
  echo "ERROR: this build host has architecture ${HOST_ARCH}, while a build for ${ARCH} was requested!"
  exit 1
fi
if [[ -z ${ARCH} ]]; then
  ARCH=${HOST_ARCH}
fi
echo "A compatibility layer for architecture ${ARCH} will be built."

# Make a temporary directory on the host for storing the installation and some temporary files
TMPDIR=${STORAGE:-${TMPDIR:-/tmp}}
mkdir -p ${TMPDIR}
EESSI_TMPDIR=$(mktemp -d --tmpdir eessi.XXXXXXXXXX)
echo "Using $EESSI_TMPDIR as temporary storage..."

# Create temporary directories
mkdir -p ${EESSI_TMPDIR}/cvmfs
mkdir -p ${EESSI_TMPDIR}/home

# Set up paths and mount points for Apptainer
export APPTAINER_CACHEDIR=${EESSI_TMPDIR}/apptainer_cache
export APPTAINER_BIND="${EESSI_TMPDIR}/cvmfs:/cvmfs,${SCRIPT_DIR}:/compatibility-layer"
export APPTAINER_HOME="${EESSI_TMPDIR}/home:/home/${USER}"

# Construct the Ansible playbook command
ANSIBLE_OPTIONS="-e eessi_host_os=linux -e eessi_host_arch=$(uname -m)"
if [[ ! -z ${VERSION} ]]; then
    ANSIBLE_OPTIONS="${ANSIBLE_OPTIONS} -e eessi_version=${VERSION}"
fi
if [[ ! -z ${REPOSITORY} ]]; then
    ANSIBLE_OPTIONS="${ANSIBLE_OPTIONS} -e cvmfs_repository=${REPOSITORY}"
fi
ANSIBLE_COMMAND="ansible-playbook ${ANSIBLE_OPTIONS} /compatibility-layer/ansible/playbooks/install.yml"
# Finally, run Ansible inside the container to do the actual installation
echo "Executing ${ANSIBLE_COMMAND} in ${CONTAINER}, this will take a while..."
apptainer shell ${CONTAINER} <<EOF
# The Gentoo Prefix bootstrap script will complain if $LD_LIBRARY_PATH is set
unset LD_LIBRARY_PATH
${ANSIBLE_COMMAND}
EOF
