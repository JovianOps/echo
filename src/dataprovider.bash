#!/usr/bin/env bash
##
# @file
# Data providers: run one function over many cases, plus matrix expansion.
#
# Cases are 'name|arg1|arg2|...' strings. The runner calls
# FUNCTION with each case's args; an optional ASSERT_FN receives the case name
# and the function's output for custom assertions.
#

##
# Build a case string from a name and arguments.
#
# Arguments:
#   1. name: Case name.
#   2+. args: Case arguments.
#
# Outputs:
#   STDOUT: The case string.
##
dataprovider_case() {
  if [ "$#" -lt 1 ]; then flunk "dataprovider_case requires a name."; return 1; fi
  local name="${1}"
  shift
  printf '%s' "${name}"
  local arg
  for arg in "$@"; do
    printf '|%s' "${arg}"
  done
  printf '\n'
}

##
# Expand variables into a cartesian matrix of case strings.
#
# Arguments, repeated:
#   VAR "value1 value2" — values are whitespace-separated.
#
# Outputs:
#   STDOUT: One 'VAR1=value1 VAR2=value2 ...' line per combination. The caller
#   splits each line back into assignments before invoking its function.
##
dataprovider_matrix() {
  if [ "$#" -eq 0 ] || [ $(( $# % 2 )) -ne 0 ]; then
    flunk "dataprovider_matrix requires VAR and value-list pairs."
    return 1
  fi

  local -a output=("")

  while [ "$#" -gt 0 ]; do
    local var="${1}"
    local -a grown=()
    local prefix
    local value

    for prefix in ${output[@]+"${output[@]}"}; do
      for value in ${2}; do
        if [ -z "${prefix}" ]; then
          grown+=("${var}=${value}")
        else
          grown+=("${prefix} ${var}=${value}")
        fi
      done
    done

    output=(${grown[@]+"${grown[@]}"})
    shift 2
  done

  printf '%s\n' ${output[@]+"${output[@]}"}
}

##
# Run a function over cases.
#
# Arguments:
#   1. function: Function to call with each case's args.
#   2. assert_fn: Optional assertion receiving case name and output.
#   3+. cases: Case strings from dataprovider_case.
##
dataprovider_run() {
  if [ "$#" -lt 2 ]; then flunk "dataprovider_run requires a function and at least one case."; return 1; fi
  local function="${1}"
  local assert_fn="${2}"
  shift 2

  if ! declare -F "${function}" >/dev/null; then
    flunk "Case function '${function}' is not defined."
    return 1
  fi

  if [ -n "${assert_fn}" ] && ! declare -F "${assert_fn}" >/dev/null; then
    flunk "Assert function '${assert_fn}' is not defined."
    return 1
  fi

  local case_string
  local name
  local -a args
  local rest
  local output
  local failed=0

  for case_string in "$@"; do
    name="${case_string%%|*}"
    rest="${case_string#*|}"
    args=()

    if [ "${rest}" != "${case_string}" ]; then
      local IFS='|'
      read -r -a args <<< "${rest}"
      unset IFS
    fi

    output="$("${function}" "${args[@]+${args[@]}}")"
    local status="$?"

    if [ -n "${assert_fn}" ]; then
      "${assert_fn}" "${name}" "${output}" || failed=1
    elif [ "${status}" -ne 0 ]; then
      echo "case '${name}' failed with status ${status}" >&2
      failed=1
    fi
  done

  return "${failed}"
}

dataprovider_run_cases() { dataprovider_run "$@"; }
