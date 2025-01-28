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


# stop as soon as something fails
# set -e

TOPDIR=$(dirname $(realpath $0))

source ${TOPDIR}/../scripts/utils.sh
source ${TOPDIR}/../scripts/cfg_files.sh

#source scripts/utils.sh
#source scripts/cfg_files.sh

# defaults
export JOB_CFG_FILE="${JOB_CFG_FILE_OVERRIDE:=./cfg/job.cfg}"

# check if ${JOB_CFG_FILE} exists
if [[ ! -r "${JOB_CFG_FILE}" ]]; then
    echo_red "job config file (JOB_CFG_FILE=${JOB_CFG_FILE}) does not exist or not readable"
else
    echo "bot/check-build.sh: showing ${JOB_CFG_FILE} from software-layer side"
    cat ${JOB_CFG_FILE}

    echo "bot/check-build.sh: obtaining configuration settings from '${JOB_CFG_FILE}'"
    cfg_load ${JOB_CFG_FILE}
fi

display_help() {
  echo "usage: $0 [OPTIONS]"
  echo " OPTIONS:"
  echo "  -h | --help    - display this usage information [default: false]"
  echo "  -v | --verbose - display more information [default: false]"
}

# set defaults for command line arguments
VERBOSE=0

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      display_help
      exit 0
      ;;
    -v|--verbose)
      VERBOSE=1
      shift 1
      ;;
    --)
      shift
      POSITIONAL_ARGS+=("$@") # save positional args
      break
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

job_dir=${PWD}

[[ ${VERBOSE} -ne 0 ]] && echo ">> analysing job in directory ${job_dir}"

cpu_target_arch=$(cfg_get_value "architecture" "software_subdir" | cut -d/ -f1)
[[ ${VERBOSE} -ne 0 ]] && echo ">> cfg[architecture][software_subdir] = ${cpu_target_arch}"

host_arch=$(uname -m)
eessi_arch=${cpu_target_arch:-${host_arch}}
# eessi_os=linux
job_version=$(cfg_get_value "repository" "repo_version")
# eessi_version=${job_version:-2023.09}
# eessi_version=2025.01
# job_repo=$(cfg_get_value "repository" "repo_name")
# eessi_repo=${job_repo:-pilot.nessi.no}
# tar_topdir=/cvmfs/${eessi_repo}/versions

# determine job output file
job_out_file=slurm-${SLURM_JOB_ID}.out
job_result_file=_bot_job${SLURM_JOB_ID}.result
if [[ ! -e ${job_out_file} ]]; then
    SLURM=0
else
    SLURM=1
fi

# status of build job (SUCCESS/FAILURE) + details
# SUCCESS (all of)
# - last line with failed=0
# - tarball
# FAILED (one of)
# - no last line with failed=0
# - no tarball

if [[ ${SLURM} -eq 1 ]]; then
    play_recap=0
    PLAY_RECAP=$(grep -A1 "PLAY RECAP" ${job_out_file})
    ec=$?
    [[ ${VERBOSE} -ne 0 ]] && echo "PLAY_RECAP.ec=${ec}"
    [[ ${ec} -eq 0 ]] && play_recap=0 || play_recap=1
    [[ ${VERBOSE} -ne 0 ]] && echo "play_recap=${play_recap}"
    
    found_line_with_failed=0
    echo "${PLAY_RECAP}" | grep "failed=" > /dev/null
    ec=$?
    [[ ${VERBOSE} -ne 0 ]] && echo "FAILED=.ec=${ec}"
    [[ ${ec} -eq 0 ]] && found_line_with_failed=0 || found_line_with_failed=1
    [[ ${VERBOSE} -ne 0 ]] && echo "found_line_with_failed=${found_line_with_failed}"
    
    failed_eq_zero=0
    echo "${PLAY_RECAP}" | grep "failed=0" > /dev/null
    ec=$?
    [[ ${VERBOSE} -ne 0 ]] && echo "FAILED=0.ec=${ec}"
    [[ ${ec} -eq 0 ]] && failed_eq_zero=0 || failed_eq_zero=1
    [[ ${VERBOSE} -ne 0 ]] && echo "failed_eq_zero=${failed_eq_zero}"
fi

found_tarballs=0
tarballs=$(ls eessi-*-compat-linux-${eessi_arch}-*.tar.gz 2>&1)
ec=$?
[[ ${VERBOSE} -ne 0 ]] && echo "TARBALLS.ec=${ec}"
if [[ ${ec} -eq 0 ]]; then
    found_tarballs=0
else
    found_tarballs=1
fi
[[ ${VERBOSE} -ne 0 ]] && echo "found_tarballs=${found_tarballs}"

# construct and write complete PR comment
comment_template="<details>__SUMMARY_FMT__<dl>__DETAILS_FMT____ARTEFACTS_FMT__</dl></details>"
comment_summary_fmt="<summary>__SUMMARY__ _(click triangle for details)_</summary>"
comment_details_fmt="<dt>_Details_</dt><dd>__DETAILS_LIST__</dd>"
comment_success_item_fmt=":white_check_mark: __ITEM__"
comment_failure_item_fmt=":x: __ITEM__"
comment_artefacts_fmt="<dt>_Artefacts_</dt><dd>__ARTEFACTS_LIST__</dd>"
comment_artefact_details_fmt="<details>__ARTEFACT_SUMMARY____ARTEFACT_DETAILS__</details>"

function print_br_item() {
    format="${1}"
    item="${2}"
    echo -n "${format//__ITEM__/${item}}<br/>"
}

function print_br_item2() {
    format="${1}"
    item="${2}"
    item2="${3}"
    format1="${format//__ITEM__/${item}}"
    echo -n "${format1//__ITEM2__/${item2}}<br/>"
}

function print_code_item() {
    format="${1}"
    item="${2}"
    echo -n "<code>${format//__ITEM__/${item}}</code>"
}

function print_dd_item() {
    format="${1}"
    item="${2}"
    echo -n "<dd>${format//__ITEM__/${item}}</dd>"
}

function print_list_item() {
    format="${1}"
    item="${2}"
    echo -n "<li>${format//__ITEM__/${item}}</li>"
}

function print_pre_item() {
    format="${1}"
    item="${2}"
    echo -n "<pre>${format//__ITEM__/${item}}</pre>"
}

function success() {
    format="${comment_success_item_fmt}"
    item="$1"
    print_br_item "${format}" "${item}"
}

function failure() {
    format="${comment_failure_item_fmt}"
    item="$1"
    print_br_item "${format}" "${item}"
}

function add_detail() {
    actual=${1}
    expected=${2}
    success_msg="${3}"
    failure_msg="${4}"
    if [[ ${actual} -eq ${expected} ]]; then
        success "${success_msg}"
    else
        failure "${failure_msg}"
    fi
}

if [[ ${failed_eq_zero} -eq 0 ]] && [[ ${found_tarballs} -eq 0 ]]; then
    status="SUCCESS"
    summary=":grin: SUCCESS"
else
    status="FAILURE"
    summary=":cry: FAILURE"
fi

# TODO adjust format to what NESSI bot uses
echo "[RESULT]" > ${job_result_file}
echo -n "comment_description = " >> ${job_result_file}

# construct values for placeholders in comment_template:
# - __SUMMARY_FMT__ -> variable $comment_summary
# - __DETAILS_FMT__ -> variable $comment_details
# - __ARTEFACTS_FMT__ -> variable $comment_artefacts

comment_summary="${comment_summary_fmt/__SUMMARY__/${summary}}"

# first construct comment_details_list, abbreviated CoDeList
# then use it to set comment_details
CoDeList=""

success_msg="job output file <code>${job_out_file}</code>"
failure_msg="no job output file <code>${job_out_file}</code>"
CoDeList=${CoDeList}$(add_detail ${SLURM} 1 "${success_msg}" "${failure_msg}")

success_msg="no task failed"
failure_msg="some task failed"
CoDeList=${CoDeList}$(add_detail ${failed_eq_zero} 0 "${success_msg}" "${failure_msg}")

success_msg="found tarball"
failure_msg="no tarball found"
CoDeList=${CoDeList}$(add_detail ${found_tarballs} 0 "${success_msg}" "${failure_msg}")

comment_details="${comment_details_fmt/__DETAILS_LIST__/${CoDeList}}"


# first construct comment_artefacts_list, abbreviated CoArList
# then use it to set comment_artefacts
CoArList=""

# TARBALL should only contain a single tarball
if [[ ! -z ${tarballs} ]]; then
    size="$(stat --dereference --printf=%s ${tarballs})"
    size_mib=$((${size} >> 20))
    tmpfile=$(mktemp --tmpdir=. tarfiles.XXXX)
    tar tf ${tarballs} > ${tmpfile}
    entries=$(cat ${tmpfile} | wc -l)
    artefact_summary="<summary>$(print_code_item '__ITEM__' ${tarballs})</summary>"
    CoArList=""
    CoArList="${CoArList}$(print_br_item2 'size: __ITEM__ MiB (__ITEM2__ bytes)' ${size_mib} ${size})"
    CoArList="${CoArList}$(print_br_item 'entries: __ITEM__' ${entries})"
else
    CoArList="${CoArList}$(print_dd_item 'No artefacts were created or found.' '')"
fi

comment_artefacts_details="${comment_artefact_details_fmt/__ARTEFACT_SUMMARY__/${artefact_summary}}"
comment_artefacts_details="${comment_artefacts_details/__ARTEFACT_DETAILS__/${CoArList}}"
comment_artefacts="${comment_artefacts_fmt/__ARTEFACTS_LIST__/${comment_artefacts_details}}"

# now put all pieces together creating comment_details from comment_template
comment_description=${comment_template/__SUMMARY_FMT__/${comment_summary}}
comment_description=${comment_description/__DETAILS_FMT__/${comment_details}}
comment_description=${comment_description/__ARTEFACTS_FMT__/${comment_artefacts}}

echo "${comment_description}" >> ${job_result_file}

# add overall result: SUCCESS, FAILURE, UNKNOWN + artefacts
# - this should make use of subsequent steps such as deploying a tarball more
#   efficient
echo "status = ${status}" >> ${job_result_file}
echo "artefacts = " >> ${job_result_file}
echo "${tarballs}" | sed -e 's/^/    /g' >> ${job_result_file}

# remove tmpfile
if [[ -f ${tmpfile} ]]; then
    rm ${tmpfile}
fi

# exit script with value that reflects overall job result: SUCCESS (0), FAILURE (1)
test "${status}" == "SUCCESS"
exit $?
