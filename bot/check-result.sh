#!/bin/bash
#
# Script to check the result of building the EESSI compatibility layer.
# Intended use is that it is called by a (batch) job running on a compute
# node.
#
# This script is part of the EESSI compatibility layer, see
# https://github.com/EESSI/compatibility-layer.git
#
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

# Example output
# beginning of job output
#### A compatibility layer for architecture x86_64 will be built.
#### created new temporary storage at /srv/eessi-2023.04/TS/eessi.fjgC41DsgS
#### Using /srv/eessi-2023.04/TS/eessi.fjgC41DsgS as temporary storage...
#### RUNTIME='/usr/bin/apptainer'
#### ESC[32musing runtime /usr/bin/apptainerESC[0m
#### Executing ansible-playbook -e eessi_host_os=linux -e eessi_host_arch=x86_64 -e eessi_version=2023.04 -e cvmfs_repository=pilot.eessi-hpc.org /compatibility-layer/ansible/playbooks/install.yml in docker://ghcr.io/eessi/bootstrap-prefix:debian11, this will take a while.

# good TASKs to check for
#### TASK [compatibility_layer : Create Gentoo prefix path and log directory] *******
#### changed: [localhost] => (item=/cvmfs/pilot.eessi-hpc.org/versions/2023.04/compat/linux/x86_64)
#### changed: [localhost] => (item=/tmp/eessi-logs)
#### 
#### TASK [compatibility_layer : Add custom overlay configuration] ******************
#### skipping: [localhost] => (item={'name': 'eessi', 'source': 'git', 'url': 'https://github.com/trz42/gentoo-overlay.git', 'eclass-overrides': True}) 
#### skipping: [localhost]
#### 
#### TASK [compatibility_layer : Make configuration file with overlays that can override eclasses] ***
#### ok: [localhost]
#### 
#### TASK [compatibility_layer : Sync the repositories] *****************************
#### ok: [localhost]
#### 
#### TASK [compatibility_layer : Run Gentoo Prefix bootstrap stages 1-3 via /tmp/bootstrap-prefix.sh /cvmfs/pilot.eessi-hpc.org/versions/2023.04/compat/linux/x86_64 noninteractive] ***
#### changed: [localhost]
#### 
#### TASK [compatibility_layer : Specify use flags before completing bootstrap] *****
#### changed: [localhost]
#### 
#### TASK [compatibility_layer : Continue Gentoo Prefix bootstrap via /tmp/bootstrap-prefix.sh /cvmfs/pilot.eessi-hpc.org/versions/2023.04/compat/linux/x86_64 noninteractive] ***
#### changed: [localhost]
#### 
#### TASK [compatibility_layer : (Re)install glibc with the user-defined-trusted-dirs option] ***
#### skipping: [localhost]
#### 
#### TASK [compatibility_layer : Create portage env directory] **********************
#### ok: [localhost]
#### 
#### TASK [compatibility_layer : Add env file for glibc to make sure the user-defined-trusted-dirs is always used] ***
#### ok: [localhost]
#### 
#### TASK [compatibility_layer : Install package set ['eessi-2023.04-linux-x86_64']] ***
#### ok: [localhost] => (item=eessi-2023.04-linux-x86_64)
#### 
#### TASK [compatibility_layer : Remove redundant packages] *************************
#### ok: [localhost] => (item=dev-lang/go)
#### ok: [localhost] => (item=dev-lang/go-bootstrap)
#### 
#### TASK [compatibility_layer : Run ReFrame tests] *********************************
#### ok: [localhost]

# end of job output
#### PLAY RECAP *********************************************************************
#### localhost                  : ok=17   changed=13   unreachable=0    failed=1    skipped=6    rescued=0    ignored=0   
#### localhost                  : ok=38   changed=3    unreachable=0    failed=0    skipped=5    rescued=0    ignored=1   


# stop as soon as something fails
# set -e

# TODO decide later what we actually need (scripts and cfg values)
# source utils.sh and cfg_files.sh
##source scripts/utils.sh
##source scripts/cfg_files.sh
##
### defaults
##export JOB_CFG_FILE="${JOB_CFG_FILE_OVERRIDE:=./cfg/job.cfg}"
##
### check if ${JOB_CFG_FILE} exists
##if [[ ! -r "${JOB_CFG_FILE}" ]]; then
##    fatal_error "job config file (JOB_CFG_FILE=${JOB_CFG_FILE}) does not exist or not readable"
##fi
##echo "bot/build.sh: showing ${JOB_CFG_FILE} from software-layer side"
##cat ${JOB_CFG_FILE}
##
##echo "bot/build.sh: obtaining configuration settings from '${JOB_CFG_FILE}'"
##cfg_load ${JOB_CFG_FILE}
##
##LOCAL_TMP=$(cfg_get_value "site_config" "local_tmp")
##echo "bot/build.sh: LOCAL_TMP='${LOCAL_TMP}'"
##
##echo -n "setting \$STORAGE by replacing any var in '${LOCAL_TMP}' -> "
### replace any env variable in ${LOCAL_TMP} with its
###   current value (e.g., a value that is local to the job)
##STORAGE=$(envsubst <<< ${LOCAL_TMP})
##echo "'${STORAGE}'"
##
### make sure ${STORAGE} exists
##mkdir -p ${STORAGE}
##
### obtain list of modules to be loaded
##LOAD_MODULES=$(cfg_get_value "site_config" "load_modules")
##echo "bot/build.sh: LOAD_MODULES='${LOAD_MODULES}'"
##
### load modules if LOAD_MODULES is not empty
##if [[ ! -z ${LOAD_MODULES} ]]; then
##    for mod in $(echo ${LOAD_MODULES} | tr ',' '\n')
##    do
##        echo "bot/build.sh: loading module '${mod}'"
##        module load ${mod}
##    done
##else
##    echo "bot/build.sh: no modules to be loaded"
##fi

#cpu_target_arch=$(cfg_get_value "architecture" "software_subdir" | cut -d/ -f1)
host_arch=$(uname -m)
eessi_arch=${cpu_target_arch:-${host_arch}}
eessi_os=linux
#job_version=$(cfg_get_value "repository" "repo_version")
eessi_version=${job_version:-2023.04}
#job_repo=$(cfg_get_value "repository" "repo_name")
eessi_repo=${job_repo:-pilot.eessi-hpc.org}
tar_topdir=/cvmfs/${eessi_repo}/versions

# determine job output file
job_out_file=slurm-${SLURM_JOB_ID}.out
job_result_file=_bot_job${SLURM_JOB_ID}.result
if [[ ! -e ${job_out_file} ]]; then
    echo "[RESULT]" > ${job_result_file}
    echo "summary = :thinking: UNKNOWN" >> ${job_result_file}
    echo "details = _job output file '${job_out_file}' not found/not accessible_" >> ${job_result_file}
    exit 0
fi

# status of build job (SUCCESS/FAILURE) + details
# SUCCESS (all of)
# - last line with failed=0
# - tarball
# FAILED (one of)
# - no last line with failed=0
# - no tarball

play_recap=0
PLAY_RECAP=$(grep -A1 "PLAY RECAP" ${job_out_file})
ec=$?
echo "PLAY_RECAP.ec=${ec}"
[[ ${ec} -eq 0 ]] && play_recap=0 || play_recap=1
echo "play_recap=${play_recap}"

found_line_with_failed=0
echo "${PLAY_RECAP}" | grep "failed=" > /dev/null
ec=$?
echo "FAILED=.ec=${ec}"
[[ ${ec} -eq 0 ]] && found_line_with_failed=0 || found_line_with_failed=1
echo "found_line_with_failed=${found_line_with_failed}"

failed_eq_zero=0
echo "${PLAY_RECAP}" | grep "failed=0" > /dev/null
ec=$?
echo "FAILED=0.ec=${ec}"
[[ ${ec} -eq 0 ]] && failed_eq_zero=0 || failed_eq_zero=1
echo "failed_eq_zero=${failed_eq_zero}"

found_tarballs=0
tarballs=$(ls eessi-${eessi_version}-compat-linux-${eessi_arch}-*.tar.gz 2>&1)
ec=$?
echo "TARBALLS.ec=${ec}"
if [[ ${ec} -eq 0 ]]; then
    found_tarballs=0
else
    found_tarballs=1
fi
echo "found_tarballs=${found_tarballs}"

if [[ ${failed_eq_zero} -eq 0 ]] && [[ ${found_tarballs} -eq 0 ]]; then
    # SUCCESS
    echo "[RESULT]" > ${job_result_file}
    echo "summary = :grin: SUCCESS" >> ${job_result_file}
    echo "details =" >> ${job_result_file}
    echo "    no task failed" >> ${job_result_file}
    echo "    found tarball(s)" >> ${job_result_file}
    echo "artefacts =" >> ${job_result_file}
    echo "${tarballs}" | sed -e 's/^/    /' >> ${job_result_file}
    exit 0
else
    # FAILURE
    echo "[RESULT]" > ${job_result_file}
    echo "summary = :cry: FAILURE" >> ${job_result_file}
    echo "details =" >> ${job_result_file}
    if [[ ${failed_eq_zero} -eq 0 ]]; then
        echo "    no task failed" >> ${job_result_file}
    else
        echo "    some task(s) failed" >> ${job_result_file}
    fi
    if [[ ${found_tarballs} -eq 0 ]]; then
        echo "    found tarball(s)" >> ${job_result_file}
    else
        echo "    no tarball found" >> ${job_result_file}
    fi
    echo "artefacts =" >> ${job_result_file}
    if [[ ${found_tarballs} -eq 0 ]]; then
        echo "${tarballs}" | sed -e 's/^/    /' >> ${job_result_file}
    fi
    exit 0
fi
