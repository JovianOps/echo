#!/usr/bin/env bash
##
# @file
# Failure reporting: flunk, formatted reports, diffs and stack traces.
#

##
# Fail the current test with a message.
#
# Arguments:
#   1. message: Message to print. Optional, read from STDIN when omitted.
#
# Outputs:
#   STDERR: The message with a stack trace, between banners, paths normalized.
#
# Returns:
#   1 always.
##
flunk() {
  local message

  if [ "$#" -eq 0 ]; then
    message="$(cat -)"
  else
    message="$*"
  fi

  local trace
  trace="$(_echo_stack_trace)"

  if [ -n "${trace}" ]; then
    message="${message}"$'\n\n'"$(_echo_boxed "stack trace" "${trace}")"
  fi

  _echo_tidy_paths "$(_echo_banner "${message}")" >&2

  return 1
}

##
# Render a titled block of key/value rows.
#
# Rows whose value spans lines switch the whole report to a labelled form with
# line counts. Rows keyed 'expected' and 'actual' collapse into a unified diff
# once either side spans lines.
#
# Arguments:
#   1. title: Short summary.
#   2+. key value: Rows, a key and a value each.
#
# Outputs:
#   STDOUT: The formatted report.
##
format_error() {
  if [ "$#" -eq 0 ]; then
    flunk "A failure report requires a title."
    return 1
  fi

  local title="${1}"
  shift

  if [ $(( $# % 2 )) -ne 0 ]; then
    flunk "Failure report rows require a key and a value each."
    return 1
  fi

  local -a keys=()
  local -a values=()
  local width=0
  local multiline=0
  local expected_index=-1
  local actual_index=-1

  while [ "$#" -gt 0 ]; do
    case "${1}" in
      expected) expected_index="${#keys[@]}" ;;
      actual) actual_index="${#keys[@]}" ;;
    esac

    [ "${#1}" -gt "${width}" ] && width="${#1}"

    case "${2}" in
      *$'\n'*) multiline=1 ;;
    esac

    keys+=("${1}")
    values+=("${2}")

    shift 2
  done

  local diffable=0

  if [ "${expected_index}" -ge 0 ] && [ "${actual_index}" -ge 0 ]; then
    case "${values[expected_index]}${values[actual_index]}" in
      *$'\n'*) diffable=1 ;;
    esac
  fi

  local body=""
  local i

  for ((i = 0; i < ${#keys[@]}; i++)); do
    if [ "${diffable}" = "1" ] && [ "${i}" -eq "${actual_index}" ]; then
      continue
    fi

    if [ "${diffable}" = "1" ] && [ "${i}" -eq "${expected_index}" ]; then
      body="${body}$(_echo_diff "${values[expected_index]}" "${values[actual_index]}")"$'\n'
      continue
    fi

    if [ "${multiline}" = "1" ]; then
      body="${body}${keys[i]} ($(_echo_line_count "${values[i]}")):"$'\n'"${values[i]}"$'\n'
      continue
    fi

    body="${body}$(printf '%-*s : %s' "${width}" "${keys[i]}" "${values[i]}")"$'\n'
  done

  _echo_tidy_paths "$(_echo_boxed "${title}" "${body%$'\n'}")"
}

##
# Wrap a failure so it stands out in a wall of test output.
#
# Arguments:
#   1. body: Failure to wrap.
#
# Outputs:
#   STDOUT: The body between banners.
##
_echo_banner() {
  echo "##################################################"
  echo "#             BEGIN ERROR MESSAGE                #"
  echo "##################################################"
  printf '%s\n' "${1}"
  echo "##################################################"
  echo "#              END ERROR MESSAGE                 #"
  echo "##################################################"
}

##
# Wrap a block of text in a titled border.
#
# Arguments:
#   1. title: Name of the block.
#   2. body: Text to wrap. Optional.
#
# Outputs:
#   STDOUT: The bordered block.
##
_echo_boxed() {
  printf -- '-- %s --\n' "${1}"

  if [ -n "${2-}" ]; then
    printf '%s\n' "${2}"
  fi

  printf -- '--\n'
}

##
# Render a unified diff of two values.
#
# Arguments:
#   1. expected: Expected value.
#   2. actual: Actual value.
#
# Outputs:
#   STDOUT: The diff labelled per side.
##
_echo_diff() {
  local -a options=(-u -L expected -L actual)

  if _echo_color_on; then
    options+=(--color=always)
  fi

  # diff exits non-zero precisely when there is something to show.
  diff "${options[@]}" <(printf '%s\n' "${1}") <(printf '%s\n' "${2}") || true
}

##
# Count the lines a value spans, at least one.
#
# Arguments:
#   1. value: Value to measure.
#
# Outputs:
#   STDOUT: The count with its noun.
##
_echo_line_count() {
  local flat="${1//$'\n'/}"
  local count=$((${#1} - ${#flat} + 1))

  if [ "${count}" -eq 1 ]; then
    printf '1 line\n'
  else
    printf '%s lines\n' "${count}"
  fi
}

##
# Whether diff output should be coloured.
#
# Globals:
#   ECHO_REPORT_COLOR: '0' never colours, '1' colours when supported. Unset
#     defers to NO_COLOR.
#   NO_COLOR: Any non-empty value suppresses colour.
#
# Returns:
#   0 when colour is wanted, 1 when not.
##
_echo_color_on() {
  local override="${ECHO_REPORT_COLOR-}"

  [ "${override}" = "0" ] && return 1

  if [ "${override}" != "1" ] && [ -n "${NO_COLOR-}" ]; then
    return 1
  fi

  diff --color=always /dev/null /dev/null >/dev/null 2>&1
}

##
# Print the call stack outside this library and bats-core.
#
# Globals:
#   BATS_ROOT: bats-core installation directory, skipped like library frames.
#
# Outputs:
#   STDOUT: One 'file:line: function' entry per frame, outermost last.
##
_echo_stack_trace() {
  local root="${BASH_SOURCE[0]%/*}"
  local bats_root="${BATS_ROOT-}"
  local source
  local i

  for ((i = 1; i < ${#FUNCNAME[@]}; i++)); do
    source="${BASH_SOURCE[i + 1]-}"

    [ -z "${source}" ] && break

    case "${source}" in
      "${root}"/*) continue ;;
    esac

    if [ -n "${bats_root}" ]; then
      case "${source}" in
        "${bats_root}"/*) continue ;;
      esac
    fi

    printf '%s:%s: %s\n' "${source}" "${BASH_LINENO[i]}" "${FUNCNAME[i]}"
  done
}

##
# Rewrite volatile paths to the variable names holding them.
#
# Arguments:
#   1. text: Text to rewrite.
#
# Globals:
#   BATS_TEST_SOURCE, BATS_TEST_FILENAME, BATS_TEST_TMPDIR, BATS_FILE_TMPDIR,
#   BATS_SUITE_TMPDIR, BATS_RUN_TMPDIR, PWD, HOME.
#
# Outputs:
#   STDOUT: The rewritten text.
##
_echo_tidy_paths() {
  local text="${1}"

  if [ -n "${BATS_TEST_SOURCE-}" ] && [ -n "${BATS_TEST_FILENAME-}" ]; then
    text="${text//"${BATS_TEST_SOURCE}"/${BATS_TEST_FILENAME}}"
  fi

  local name
  local value

  for name in BATS_TEST_TMPDIR BATS_FILE_TMPDIR BATS_SUITE_TMPDIR BATS_RUN_TMPDIR PWD HOME; do
    value="${!name-}"

    if [ -z "${value}" ] || [ "${value}" = "/" ]; then
      continue
    fi

    text="${text//"${value}"/\${${name}}}"
  done

  printf '%s\n' "${text}"
}
