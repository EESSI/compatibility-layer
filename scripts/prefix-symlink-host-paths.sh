#!/bin/bash

function echo_green() {
    echo -e "\e[32m$1\e[0m"
}

function echo_red() {
    echo -e "\e[31m$1\e[0m"
}

function echo_yellow() {
    echo -e "\e[33m$1\e[0m"
}

if [ -z $EPREFIX ]; then
    echo_red "ERROR: \$EPREFIX not defined" >&2
    exit 1
fi

EXPECTED_START='/cvmfs/pilot.eessi-hpc.org'
if [[ $EPREFIX != $EXPECTED_START/* ]]; then
    echo_red "ERROR: \$EPREFIX does not start with '$EXPECTED_START': EPREFIX=$EPREFIX" >&2
    exit 1
fi

# /etc/passwd: required to ensure local users are known (see https://github.com/EESSI/compatibility-layer/issues/15)
# /etc/group: required to ensure local user groups are known
for path in /etc/passwd /etc/group; do
    echo ">> checking $path ..."
    ls -ld ${EPREFIX}$path | grep " -> $path" > /dev/null
    ec=$?
    if [ $ec -ne 0 ]; then
        echo_yellow ">> [CHANGE] ${EPREFIX}$path is *not* a symlink to $path, fixing that..."
        rm ${EPREFIX}$path
        ln -s $path ${EPREFIX}$path
    else
        echo_green ">> [OK] ${EPREFIX}$path is already a symlink to $path"
    fi
done
