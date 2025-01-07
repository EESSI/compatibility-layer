#!/bin/bash

EESSI_REPO_DIR=${EESSI_CVMFS_REPO:-/cvmfs/software.eessi.io}
EESSI_VERSION=${EESSI_VERSION:-2023.06}
EESSI_ARCH=${EESSI_CPU_FAMILY:-$(uname -m)}
EESSI_OS=${EESSI_OS_TYPE:-linux}

display_help() {
  echo "usage: $0 [OPTIONS]"
  echo "OPTIONS:"
  echo "    -a | --arch ARCHITECTURE"
  echo "        Architecture of compatibility layer to be tested"
  echo "        [default: \$EESSI_CPU_FAMILY or current host's architecture]"
  echo ""
  echo "    -g | --storage DIRECTORY"
  echo "        directory space on host machine (used for"
  echo "        temporary data) [default: 1. TMPDIR, 2. /tmp]"
  echo ""
  echo "    -h | --help"
  echo "        display this usage information"
  echo ""
  echo "    -o | --os"
  echo "        Operating system of compatibility to be tested"
  echo "        [default: \$EESSI_OS_TYPE or linux]"
  echo ""
  echo "    -r | --repository REPO"
  echo "        CVMFS repository [default: \$EESSI_CVMFS_REPO or software.eessi.io]"
  echo "        Note that this has to be mounted as /cvmfs/${REPOSITORY}!"
  echo ""
  echo "    -v | --version VERSION"
  echo "        version of EESSI stack to be tested [default: \$EESSI_VERSION or 2023.06]"
  echo ""
  echo "    --verbose"
  echo "        increase verbosity of output [default: not set]"
  echo
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--arch)
      EESSI_ARCH="$2"
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
    -o|--os)
      EESSI_OS="$2"
      shift 2
      ;;
    -r|--repository)
      EESSI_REPO_DIR="/cvmfs/$2"
      shift 2
      ;;
    -v|--version)
      EESSI_VERSION="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE="-vvv"
      shift 1
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


COMPAT_LAYER_PREFIX="${EESSI_REPO_DIR}/versions/${EESSI_VERSION}/compat/${EESSI_OS}/${EESSI_ARCH}"
if [ ! -d ${COMPAT_LAYER_PREFIX} ]; then
    echo "Directory ${COMPAT_LAYER_PREFIX} does not exist, please provide a correct path, version, and architecture."
    exit 1
fi
if [ ! -f ${COMPAT_LAYER_PREFIX}/startprefix ]; then
    echo "Cannot find a startprefix file in ${COMPAT_LAYER_PREFIX}!"
    exit 1
fi

# We assume that this script is located in a directory containing a full checkout of the git repo,
# and verify this by checking for the existance of the ReFrame test script.
SCRIPT_DIR=$(dirname $(realpath $0))
if [ ! -f "${SCRIPT_DIR}/test/compat_layer.py" ]; then
    echo "ReFrame test script compat_layer.py cannot be found!"
    echo "Make sure to run this script from a directory containing a the compatibility-layer git repository."
    exit 1
fi

if [ -z ${EESSI_TMPDIR} ];
then
  EESSI_TMPDIR=$(mktemp -t -d eessi.XXXXXXXXXX)
fi

echo "Using ${EESSI_TMPDIR} as temporary directory."

if ! command -v "reframe" &>/dev/null; then
  echo "ReFrame command not found, trying to install it to a temporary directory..."
  pip3 install --ignore-installed -t ${EESSI_TMPDIR}/reframe reframe-hpc
  export PYTHONPATH=${EESSI_TMPDIR}/reframe
  export PATH="${EESSI_TMPDIR}/reframe/bin/:${PATH}"
fi

echo "Trying to run 'reframe --version' as sanity check..."
if ! reframe --version; then
  echo "Cannot run ReFrame, giving up. Please install it manually and add it to your \$PATH."
  exit 1
fi

echo "Running the tests with: ${EESSI_TMPDIR}/reframe/bin/reframe -r -v -c ${SCRIPT_DIR}/test/compat_layer.py"
export EESSI_REPO_DIR EESSI_VERSION EESSI_ARCH EESSI_OS
export RFM_PREFIX=$PWD/reframe_runs
${EESSI_TMPDIR}/reframe/bin/reframe --nocolor -r -v -c ${SCRIPT_DIR}/test/compat_layer.py

