#!/usr/bin/env bash
##
# @file
# Step runner: run shell snippets in order, stopping loudly at the first.
#

##
# Run steps in order.
#
# Arguments, repeated:
#   description, command-string — the command runs via 'bash -c' and must
#   exit zero; anything else stops the run with a step report.
##
steps_run() {
  if [ "$#" -eq 0 ] || [ $(( $# % 2 )) -ne 0 ]; then
    flunk "steps_run requires description and command pairs."
    return 1
  fi

  local description
  local command
  local output
  local step=0

  while [ "$#" -gt 0 ]; do
    description="${1}"
    command="${2}"
    shift 2
    step=$((step + 1))

    output="$(bash -c "${command}" 2>&1)"
    local status="$?"

    if [ "${status}" -ne 0 ]; then
      format_error "Step failed" "step" "${step}: ${description}" "status" "${status}" "output" "${output}" | flunk
      return 1
    fi
  done
}

run_steps() { steps_run "$@"; }
