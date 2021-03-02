#!/usr/bin/env bats

# Before running any tests, check if ${EESSI_COMPAT_DIR} is set to a Gentoo Prefix installation.
setup_file() {
  if [ -z "${EESSI_COMPAT_DIR}" ] || [ ! -f "${EESSI_COMPAT_DIR}/startprefix" ]; then
    echo 'Please set $EESSI_COMPAT_DIR to the root of the Gentoo Prefix installation, which contains the startprefix script.'
    exit
  fi
}

# Wrapper around the BATS run function that actually runs the given command in a startprefix environment.
# It will set the exit status of the command to the status returned by the startprefix script,
# and set the output result to the line between the "Entering / Leaving Gentoo Prefix" lines.
run_prefix() {
  run "${EESSI_COMPAT_DIR}"/startprefix <<< "$@"
  status=$(awk '{print $NF}' <<< ${lines[-1]})
  output=${lines[@]:1:${#lines[@]} - 2}
}


################
# ACTUAL TESTS #
################

@test "make sure startprefix can be used" {
  run_prefix echo "hello"
  [ "$output" = "hello" ]
  [ "$status" -eq 0 ]
}

@test "run emerge" {
  run_prefix emerge --version
  [ "$status" -eq 0 ]
}

@test "run equery" {
  run_prefix equery --version
  [ "$status" -eq 0 ]
}

@test "run archspec cpu" {
  run_prefix archspec cpu
  [ "$status" -eq 0 ]
}

@test "source Lmod init file and run module avail" {
  run_prefix "source ${EESSI_COMPAT_DIR}/usr/lmod/lmod/init/profile && module avail"
  [ "$status" -eq 0 ]
}

@test "check if user can be resolved in Prefix" {
  run_prefix "whoami"
  [ "$status" -eq 0 ]
  [ "$output" = "$(whoami)" ]
}

@test "check if EESSI sets are available" {
  run_prefix "emerge --list-sets | grep eessi-"
  [ "$status" -eq 0 ]
}

@test "check if en_US.utf8 locale is available" {
  run_prefix "locale -a | grep '^en_US.utf8$'"
  [ "$status" -eq 0 ]
}
