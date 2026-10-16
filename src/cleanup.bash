#!/usr/bin/env bash
##
# @file
# Deferred cleanup: register removals next to the code that creates them.
#
# Commands run last-registered-first when cleanup_run executes, so nested
# resources unwind in the order they were built.
#

##
# Path of the registry file for this test.
##
cleanup_registry_path() {
  printf '%s\n' "${BATS_TEST_TMPDIR:-${TMPDIR:-/tmp}}/echo-cleanup.$$"
}

##
# Register a command to run at cleanup.
#
# Arguments:
#   1. command: Shell snippet to eval later. Quote paths yourself; redirects
#      and operators work because the string runs unquoted.
##
cleanup_register() {
  if [ "$#" -eq 0 ]; then
    flunk "cleanup_register requires a command."
    return 1
  fi

  printf '%s\n' "$*" >> "$(cleanup_registry_path)"
}

##
# Run every registered command, most recent first.
#
# A failing command is reported but does not stop the rest.
##
cleanup_run() {
  local registry
  registry="$(cleanup_registry_path)"

  if [ ! -f "${registry}" ]; then
    return 0
  fi

  local -a commands=()
  local line

  while IFS= read -r line || [ -n "${line}" ]; do
    commands=("${line}" "${commands[@]}")
  done < "${registry}"

  local failed=0
  local i
  local command

  for ((i = 0; i < ${#commands[@]}; i++)); do
    command="${commands[i]}"

    if ! eval "${command}"; then
      echo "cleanup failed: ${command}" >&2
      failed=1
    fi
  done

  rm -f "${registry}"

  return "${failed}"
}
