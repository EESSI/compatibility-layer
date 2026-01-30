#!/bin/bash
#
# script to build the EESSI compatibility layer. Intended use is that it is called
# by a (batch) job running on a compute node.
#
# This script is part of the EESSI compatibility layer, see
# https://github.com/EESSI/compatibility-layer.git
#
# author: Bob Droege (@bedroge)
# author: Thomas Roeblitz (@trz42)
#
# license: GPLv2
#

# ASSUMPTIONs:
#  - working directory has been prepared by the bot with a checkout of a
#    pull request (OR by some other means)
#  - the working directory contains a directory 'cfg' where the main config
#    file 'job.cfg' has been deposited
#  - the directory may contain any additional files referenced in job.cfg

# stop as soon as something fails
set -e

# source utils.sh and cfg_files.sh
source scripts/utils.sh
source scripts/cfg_files.sh

# defaults
export JOB_CFG_FILE="${JOB_CFG_FILE_OVERRIDE:=./cfg/job.cfg}"

# check if ${JOB_CFG_FILE} exists
if [[ ! -r "${JOB_CFG_FILE}" ]]; then
    fatal_error "job config file (JOB_CFG_FILE=${JOB_CFG_FILE}) does not exist or not readable"
fi
echo "bot/build.sh: showing ${JOB_CFG_FILE} from software-layer side"
cat ${JOB_CFG_FILE}

echo "bot/build.sh: obtaining configuration settings from '${JOB_CFG_FILE}'"
cfg_load ${JOB_CFG_FILE}

# if http_proxy is defined in ${JOB_CFG_FILE} use it, if not use env var $http_proxy
HTTP_PROXY=$(cfg_get_value "site_config" "http_proxy")
HTTP_PROXY=${HTTP_PROXY:-${http_proxy}}
echo "bot/build.sh: HTTP_PROXY='${HTTP_PROXY}'"

# if https_proxy is defined in ${JOB_CFG_FILE} use it, if not use env var $https_proxy
HTTPS_PROXY=$(cfg_get_value "site_config" "https_proxy")
HTTPS_PROXY=${HTTPS_PROXY:-${https_proxy}}
echo "bot/build.sh: HTTPS_PROXY='${HTTPS_PROXY}'"

LOCAL_TMP=$(cfg_get_value "site_config" "local_tmp")
echo "bot/build.sh: LOCAL_TMP='${LOCAL_TMP}'"

echo -n "setting \$STORAGE by replacing any var in '${LOCAL_TMP}' -> "
# replace any env variable in ${LOCAL_TMP} with its
#   current value (e.g., a value that is local to the job)
STORAGE=$(envsubst <<< ${LOCAL_TMP})
echo "'${STORAGE}'"

# make sure ${STORAGE} exists
mkdir -p ${STORAGE}

# obtain list of modules to be loaded
LOAD_MODULES=$(cfg_get_value "site_config" "load_modules")
echo "bot/build.sh: LOAD_MODULES='${LOAD_MODULES}'"

# load modules if LOAD_MODULES is not empty
if [[ ! -z ${LOAD_MODULES} ]]; then
    for mod in $(echo ${LOAD_MODULES} | tr ',' '\n')
    do
        echo "bot/build.sh: loading module '${mod}'"
        module load ${mod}
    done
else
    echo "bot/build.sh: no modules to be loaded"
fi

cpu_target_arch=$(cfg_get_value "architecture" "software_subdir" | cut -d/ -f1)
host_arch=$(uname -m)
eessi_arch=${cpu_target_arch:-${host_arch}}
eessi_os=linux
job_version=$(cfg_get_value "repository" "repo_version")
job_repo=$(cfg_get_value "repository" "repo_name")
eessi_repo=${job_repo:-software.eessi.io}
tar_topdir=/cvmfs/${eessi_repo}/versions

# Check the architecture, which has to match the architecture of the build host
if [[ "${eessi_arch}" != "${host_arch}" ]]; then
  echo "bot/build.sh: requested architecture (${eessi_arch}) is different from this machine's architecture ($(uname -m))!"
  exit 1
fi

# Read and check the build type (new or update, case-insensitive)
if [[ ! -f bot/build_type ]]; then
    echo 'bot/build.sh: cannot determine build type, please add a file "bot/build_type" containing either "new" or "update".'
    exit 1
fi
build_type=$(cat bot/build_type | tr '[:upper:]' '[:lower:]')
if [[ "${build_type}" != "new" && "${build_type}" != "update" ]]; then
    echo 'bot/build.sh: invalid build type! It has to be "new" or "update".'
    exit 1
fi
echo "bot/build.sh: requested build type '${build_type}'"

# Set up the script arguments and run the installation script
script_out="install_stdout.log"
script_args=(-a ${eessi_arch} -r ${eessi_repo} -g ${STORAGE} -k)
# for (very!) verbose output, uncomment:
#script_args+=(--verbose)
if [[ "${build_type}" == "update" ]]; then
    script_args+=(-u)
fi
./install_compatibility_layer.sh ${script_args[@]} 2>&1 | tee -a ${script_out}

# Create a tarball of the new or updated build
# TODO handle errors (no outfile, no tmp directory found, etc)
eessi_tmp=$(grep '^To resume work add' ${script_out} | cut -f 2 -d \' | cut -f 2 -d ' ' | tail -n 1)
echo "bot/build.sh: creating compatibility layer tarball..."
if [[ "${build_type}" == "update" ]]; then
    # Resume the build container session and tar the entire /cvmfs/$repo tree
    container_tmp=$(grep -oP '(?<=^Using ).*(?= as tmp directory)' ${script_out} | tail -n 1)
    container_image=$(ls -1t ${container_tmp}/*.sif | head -n 1)
    eessi_version=$(ls -1 ${container_tmp}/${eessi_repo}/overlay-upper/versions)
    target_tgz=eessi-${eessi_version}-compat-linux-${eessi_arch}-$(date +%s).tar.gz
    ${eessi_tmp}/software-layer-scripts/eessi_container.sh -c ${container_image} --mode exec --resume ${container_tmp} -r ${eessi_repo} -b ${PWD}:/eessi_job --access rw -- tar cfvz /eessi_job/${target_tgz} -C ${tar_topdir} ${eessi_version}/compat/${eessi_os}/${eessi_arch}
elif [[ "${build_type}" == "new" ]]; then
    # For a new build, we simply tar the used host directory that was bind mounted as /cvmfs/$repo
    eessi_version=$(ls -1 ${eessi_tmp}${tar_topdir})
    target_tgz=eessi-${eessi_version}-compat-linux-${eessi_arch}-$(date +%s).tar.gz
    tar cfvz ${target_tgz} -C ${eessi_tmp}${tar_topdir} ${eessi_version}/compat/${eessi_os}/${eessi_arch}
fi
