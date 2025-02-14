#!/usr/bin/env bash
#
# Script to run tests for the whole EESSI compatibility software layer.
# Intended use is that it is called at the end of a (batch) job running on a compute node.
#
# This script is part of the EESSI compatibility layer, see
# https://github.com/EESSI/compatibility-layer.git
#
# author: Thomas Roeblitz (@trz42)
# author: Caspar van Leeuwen (@casparvl)
# author: Bob Dröge (@bedroge)
#
# license: GPLv2
#

# ASSUMPTIONs:
# + assumption for the build step (as run through bot/build.sh which is provided
#   in this repository too)
#  - working directory has been prepared by the bot with a checkout of a
#    pull request (OR by some other means)
#  - the working directory contains a directory 'cfg' where the main config
#    file 'job.cfg' has been deposited
#  - the directory may contain any additional files referenced in job.cfg
# + assumptions for the test step
#  - temporary storage is still available
#    example
#    Using /tmp/bot/EESSI/eessi.7l3zm2x7qH as temporary storage...
#  - run test/compat_layer.py with ReFrame inside build container using tmp storage from build step
#    plus possibly additional settings (repo, etc.)

# stop as soon as something fails
set -e

# source utils.sh and cfg_files.sh
source scripts/utils.sh
source scripts/cfg_files.sh

# defaults
export JOB_CFG_FILE="${JOB_CFG_FILE_OVERRIDE:=./cfg/job.cfg}"
HOST_ARCH=$(uname -m)

# check if ${JOB_CFG_FILE} exists
if [[ ! -r "${JOB_CFG_FILE}" ]]; then
    fatal_error "job config file (JOB_CFG_FILE=${JOB_CFG_FILE}) does not exist or not readable"
fi
echo "bot/test.sh: showing ${JOB_CFG_FILE} from software-layer side"
cat ${JOB_CFG_FILE}

echo "bot/test.sh: obtaining configuration settings from '${JOB_CFG_FILE}'"
cfg_load ${JOB_CFG_FILE}

# if http_proxy is defined in ${JOB_CFG_FILE} use it, if not use env var $http_proxy
HTTP_PROXY=$(cfg_get_value "site_config" "http_proxy")
HTTP_PROXY=${HTTP_PROXY:-${http_proxy}}
echo "bot/test.sh: HTTP_PROXY='${HTTP_PROXY}'"

# if https_proxy is defined in ${JOB_CFG_FILE} use it, if not use env var $https_proxy
HTTPS_PROXY=$(cfg_get_value "site_config" "https_proxy")
HTTPS_PROXY=${HTTPS_PROXY:-${https_proxy}}
echo "bot/test.sh: HTTPS_PROXY='${HTTPS_PROXY}'"

LOCAL_TMP=$(cfg_get_value "site_config" "local_tmp")
echo "bot/test.sh: LOCAL_TMP='${LOCAL_TMP}'"

# try to determine tmp directory from build job
EESSI_TMPDIR=$(grep -oP "To resume work add '--resume \K.*(?=')" slurm-${SLURM_JOB_ID}.out)

if [[ -z ${EESSI_TMPDIR} ]]; then
  echo "bot/test.sh: no information about tmp directory build step; --> giving up"
  exit 2
fi

# obtain list of modules to be loaded
LOAD_MODULES=$(cfg_get_value "site_config" "load_modules")
echo "bot/test.sh: LOAD_MODULES='${LOAD_MODULES}'"

# load modules if LOAD_MODULES is not empty
if [[ ! -z ${LOAD_MODULES} ]]; then
    for mod in $(echo ${LOAD_MODULES} | tr ',' '\n')
    do
        echo "bot/test.sh: loading module '${mod}'"
        module load ${mod}
    done
else
    echo "bot/test.sh: no modules to be loaded"
fi

cpu_target_arch=$(cfg_get_value "architecture" "software_subdir" | cut -d/ -f1)
host_arch=$(uname -m)
eessi_arch=${cpu_target_arch:-${host_arch}}
eessi_os=linux
job_version=$(cfg_get_value "repository" "repo_version")
job_repo=$(cfg_get_value "repository" "repo_name")
eessi_repo=${job_repo:-software.eessi.io}
tar_topdir=/cvmfs/${eessi_repo}/versions
eessi_version=$(ls -1 ${EESSI_TMPDIR}/${tar_topdir})

if [ "${eessi_arch}" != "${host_arch}" ]; then
  echo "Requested architecture (${eessi_arch}) is different from this machine's architecture ($(uname -m))!"
  exit 1
fi

RUNTIME=$(get_container_runtime)
exit_code=$?
[[ ${VERBOSE} == '-vvv' ]] && echo "RUNTIME='${RUNTIME}'"
check_exit_code ${exit_code} "using runtime ${RUNTIME}" "oh no, neither apptainer nor singularity available"

# Set up paths and mount points for Apptainer
if [[ -z ${APPTAINER_CACHEDIR} ]]; then
  export APPTAINER_CACHEDIR=${EESSI_TMPDIR}/apptainer_cache
  [[ ${VERBOSE} == '-vvv' ]] && echo "APPTAINER_CACHEDIR='${APPTAINER_CACHEDIR}'"
fi
export APPTAINER_BIND="${EESSI_TMPDIR}/cvmfs:/cvmfs,${PWD}"
export APPTAINER_BIND="${APPTAINER_BIND},${EESSI_TMPDIR}/tmp:/tmp"
[[ ${VERBOSE} == '-vvv' ]] && echo "APPTAINER_BIND='${APPTAINER_BIND}'"
export APPTAINER_HOME="${EESSI_TMPDIR}/home:/home/${USER}"
[[ ${VERBOSE} == '-vvv' ]] && echo "APPTAINER_HOME='${APPTAINER_HOME}'"

# also define SINGULARITY_* env vars
if [[ -z ${SINGULARITY_CACHEDIR} ]]; then
  export SINGULARITY_CACHEDIR=${EESSI_TMPDIR}/apptainer_cache
  [[ ${VERBOSE} == '-vvv' ]] && echo "SINGULARITY_CACHEDIR='${SINGULARITY_CACHEDIR}'"
fi
export SINGULARITY_BIND="${EESSI_TMPDIR}/cvmfs:/cvmfs,${PWD}"
export SINGULARITY_BIND="${SINGULARITY_BIND},${EESSI_TMPDIR}/tmp:/tmp"
[[ ${VERBOSE} == '-vvv' ]] && echo "SINGULARITY_BIND='${SINGULARITY_BIND}'"
export SINGULARITY_HOME="${EESSI_TMPDIR}/home:/home/${USER}"
[[ ${VERBOSE} == '-vvv' ]] && echo "SINGULARITY_HOME='${SINGULARITY_HOME}'"

CONTAINER=docker://ghcr.io/eessi/bootstrap-prefix:debian11

${RUNTIME} exec ${CONTAINER} ./test_compatibility_layer.sh -a ${host_arch} -o linux -r ${eessi_repo} -v ${eessi_version} --verbose

exit 0
