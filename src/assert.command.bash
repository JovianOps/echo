#!/usr/bin/env bash
##
# @file
# Command assertions over the BATS 'run' variables: status, output, stderr.
#

##
# Assert the last command succeeded.
##
assert_success() {
  if [ "${status-}" -ne 0 ]; then
    format_error "Command failed" "status" "${status-}" "output" "${output-}" | flunk
    return 1
  fi
}

##
# Assert the last command failed.
##
assert_failure() {
  if [ "${status-}" -eq 0 ]; then
    format_error "Command unexpectedly succeeded" "output" "${output-}" | flunk
    return 1
  fi
}

##
# Assert the last command failed with a specific status.
#
# Arguments:
#   1. expected: Expected exit status.
##
assert_failure_status() {
  if [ "$#" -ne 1 ]; then
    flunk "assert_failure_status requires an expected status."
    return 1
  fi

  assert_failure || return 1
  assert_status "${1}"
}

##
# Assert the exact exit status of the last command.
#
# Arguments:
#   1. expected: Expected exit status.
##
assert_status() {
  if [ "$#" -ne 1 ]; then
    flunk "assert_status requires an expected status."
    return 1
  fi

  if [ "${status-}" -ne "${1}" ]; then
    format_error "Status differs" "expected" "${1}" "actual" "${status-}" "output" "${output-}" | flunk
    return 1
  fi
}

##
# Assert the last command failed with a general error (status 1).
##
assert_status_general_error() {
  assert_status 1
}

##
# Assert the last command was not found (status 127).
##
assert_status_command_not_found() {
  assert_status 127
}

##
# Assert command output, and the negated and case forms per verb.
##
assert_output() {
  if [ "$#" -ne 1 ]; then
    flunk "assert_output requires an expected value."
    return 1
  fi

  if [ "${output-}" != "${1}" ]; then
    format_error "Output differs" "expected" "${1}" "actual" "${output-}" | flunk
    return 1
  fi
}

assert_output_contains() { _echo_assert_needle contains 1 0 "output" "${output-}" "${1?}"; }
assert_output_contains_case() { _echo_assert_needle contains 1 1 "output" "${output-}" "${1?}"; }
assert_output_not_contains() { _echo_assert_needle contains 0 0 "output" "${output-}" "${1?}"; }
assert_output_not_contains_case() { _echo_assert_needle contains 0 1 "output" "${output-}" "${1?}"; }
assert_output_matches() { _echo_assert_needle matches 1 0 "output" "${output-}" "${1?}"; }
assert_output_matches_case() { _echo_assert_needle matches 1 1 "output" "${output-}" "${1?}"; }
assert_output_not_matches() { _echo_assert_needle matches 0 0 "output" "${output-}" "${1?}"; }
assert_output_not_matches_case() { _echo_assert_needle matches 0 1 "output" "${output-}" "${1?}"; }
assert_output_matches_format() { _echo_assert_needle format 1 0 "output" "${output-}" "${1?}"; }
assert_output_matches_format_case() { _echo_assert_needle format 1 1 "output" "${output-}" "${1?}"; }
assert_output_not_matches_format() { _echo_assert_needle format 0 0 "output" "${output-}" "${1?}"; }
assert_output_not_matches_format_case() { _echo_assert_needle format 0 1 "output" "${output-}" "${1?}"; }

##
# Assert stderr was captured separately (needs 'run --separate-stderr').
##
assert_stderr_captured() {
  if [ -z "${stderr+x}" ]; then
    format_error "Stderr was not captured; run the command with 'run --separate-stderr'." | flunk
    return 1
  fi
}

##
# Assert the exact stderr of the last command.
#
# Arguments:
#   1. expected: Expected stderr.
##
assert_stderr() {
  if [ "$#" -ne 1 ]; then
    flunk "assert_stderr requires an expected value."
    return 1
  fi

  assert_stderr_captured || return 1

  if [ "${stderr}" != "${1}" ]; then
    format_error "Stderr differs" "expected" "${1}" "actual" "${stderr}" | flunk
    return 1
  fi
}

##
# Assert the last command wrote nothing to stderr.
##
assert_stderr_empty() {
  assert_stderr_captured || return 1

  if [ -n "${stderr}" ]; then
    format_error "Stderr is not empty" "actual" "${stderr}" | flunk
    return 1
  fi
}

assert_stderr_contains() { assert_stderr_captured && _echo_assert_needle contains 1 0 "stderr" "${stderr}" "${1?}"; }
assert_stderr_contains_case() { assert_stderr_captured && _echo_assert_needle contains 1 1 "stderr" "${stderr}" "${1?}"; }
assert_stderr_not_contains() { assert_stderr_captured && _echo_assert_needle contains 0 0 "stderr" "${stderr}" "${1?}"; }
assert_stderr_not_contains_case() { assert_stderr_captured && _echo_assert_needle contains 0 1 "stderr" "${stderr}" "${1?}"; }
assert_stderr_matches() { assert_stderr_captured && _echo_assert_needle matches 1 0 "stderr" "${stderr}" "${1?}"; }
assert_stderr_matches_case() { assert_stderr_captured && _echo_assert_needle matches 1 1 "stderr" "${stderr}" "${1?}"; }
assert_stderr_not_matches() { assert_stderr_captured && _echo_assert_needle matches 0 0 "stderr" "${stderr}" "${1?}"; }
assert_stderr_not_matches_case() { assert_stderr_captured && _echo_assert_needle matches 0 1 "stderr" "${stderr}" "${1?}"; }
assert_stderr_matches_format() { assert_stderr_captured && _echo_assert_needle format 1 0 "stderr" "${stderr}" "${1?}"; }
assert_stderr_matches_format_case() { assert_stderr_captured && _echo_assert_needle format 1 1 "stderr" "${stderr}" "${1?}"; }
assert_stderr_not_matches_format() { assert_stderr_captured && _echo_assert_needle format 0 0 "stderr" "${stderr}" "${1?}"; }
assert_stderr_not_matches_format_case() { assert_stderr_captured && _echo_assert_needle format 0 1 "stderr" "${stderr}" "${1?}"; }
