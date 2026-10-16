#!/usr/bin/env bash
##
# @file
# Line assertions over the BATS 'lines' array.
#
# Indexes are zero-based; a negative index counts back from the last line.
# The twelve match forms from assert.string apply to single lines (assert_line)
# and to scans (assert_any_line, assert_no_line, assert_line_count).
#

##
# Resolve an index into the lines array.
#
# Arguments:
#   1. index: Zero-based index, negative counts from the end.
#
# Outputs:
#   STDOUT: The resolved non-negative index.
##
_echo_line_index() {
  local index="${1}"
  local total="${#lines[@]}"

  if [ "${index}" -lt 0 ]; then
    index=$((total + index))
  fi

  if [ "${index}" -lt 0 ] || [ "${index}" -ge "${total}" ]; then
    flunk "Line index ${1} is out of range for ${total} line(s)."
    return 1
  fi

  printf '%s\n' "${index}"
}

##
# Assert the line at an index equals the expected value.
#
# Arguments:
#   1. index: Line index.
#   2. expected: Expected line.
##
assert_line() {
  if [ "$#" -ne 2 ]; then
    flunk "assert_line requires an index and an expected value."
    return 1
  fi

  local index
  index="$(_echo_line_index "${1}")" || return 1

  if [ "${lines[index]}" != "${2}" ]; then
    format_error "Line differs" "index" "${1}" "expected" "${2}" "actual" "${lines[index]}" | flunk
    return 1
  fi
}

##
# Assert the line at an index differs from the unexpected value.
#
# Arguments:
#   1. index: Line index.
#   2. unexpected: Unexpected line.
##
assert_line_not() {
  if [ "$#" -ne 2 ]; then
    flunk "assert_line_not requires an index and an unexpected value."
    return 1
  fi

  local index
  index="$(_echo_line_index "${1}")" || return 1

  if [ "${lines[index]}" = "${2}" ]; then
    format_error "Line unexpectedly equals" "index" "${1}" "actual" "${lines[index]}" | flunk
    return 1
  fi
}

##
# Single-line needle assertions, and the negated and case forms.
##
_echo_line_needle() {
  local kind="${1}"
  local want="${2}"
  local sensitive="${3}"
  local index="${4}"
  local needle="${5}"
  local resolved

  resolved="$(_echo_line_index "${index}")" || return 1
  _echo_assert_needle "${kind}" "${want}" "${sensitive}" "line ${index}" "${lines[resolved]}" "${needle}"
}

assert_line_contains() { _echo_line_needle contains 1 0 "${1?}" "${2?}"; }
assert_line_contains_case() { _echo_line_needle contains 1 1 "${1?}" "${2?}"; }
assert_line_not_contains() { _echo_line_needle contains 0 0 "${1?}" "${2?}"; }
assert_line_not_contains_case() { _echo_line_needle contains 0 1 "${1?}" "${2?}"; }
assert_line_matches() { _echo_line_needle matches 1 0 "${1?}" "${2?}"; }
assert_line_matches_case() { _echo_line_needle matches 1 1 "${1?}" "${2?}"; }
assert_line_not_matches() { _echo_line_needle matches 0 0 "${1?}" "${2?}"; }
assert_line_not_matches_case() { _echo_line_needle matches 0 1 "${1?}" "${2?}"; }
assert_line_matches_format() { _echo_line_needle format 1 0 "${1?}" "${2?}"; }
assert_line_matches_format_case() { _echo_line_needle format 1 1 "${1?}" "${2?}"; }
assert_line_not_matches_format() { _echo_line_needle format 0 0 "${1?}" "${2?}"; }
assert_line_not_matches_format_case() { _echo_line_needle format 0 1 "${1?}" "${2?}"; }

##
# Whether any line satisfies a needle.
#
# Arguments:
#   1. kind: contains|matches|format.
#   2. sensitive: 1 for case-sensitive, 0 for case-insensitive.
#   3. needle: Needle, read per kind.
#
# Returns:
#   0 when some line satisfies it, 1 otherwise.
##
_echo_any_line() {
  local kind="${1}"
  local sensitive="${2}"
  local needle="${3}"
  local line

  for line in ${lines[@]+"${lines[@]}"}; do
    if string_match "${kind}" "${sensitive}" "${line}" "${needle}"; then
      return 0
    fi
  done

  return 1
}

assert_any_line() {
  if [ "$#" -ne 1 ]; then flunk "assert_any_line requires an expected value."; return 1; fi
  local line
  for line in ${lines[@]+"${lines[@]}"}; do
    [ "${line}" = "${1}" ] && return 0
  done
  format_error "No line equals" "expected" "${1}" "actual" "${output-}" | flunk
  return 1
}

assert_no_line() {
  if [ "$#" -ne 1 ]; then flunk "assert_no_line requires an unexpected value."; return 1; fi
  local line
  for line in ${lines[@]+"${lines[@]}"}; do
    if [ "${line}" = "${1}" ]; then
      format_error "Line unexpectedly present" "actual" "${1}" | flunk
      return 1
    fi
  done
}

assert_any_line_contains() { _echo_any_line contains 0 "${1?}" && return 0; format_error "No line contains" "needle" "${1}" "actual" "${output-}" | flunk; return 1; }
assert_any_line_contains_case() { _echo_any_line contains 1 "${1?}" && return 0; format_error "No line contains" "needle" "${1}" "actual" "${output-}" | flunk; return 1; }
assert_no_line_contains() { _echo_any_line contains 0 "${1?}" && { format_error "Line unexpectedly contains" "needle" "${1}" | flunk; return 1; }; }
assert_no_line_contains_case() { _echo_any_line contains 1 "${1?}" && { format_error "Line unexpectedly contains" "needle" "${1}" | flunk; return 1; }; }
assert_any_line_matches() { _echo_any_line matches 0 "${1?}" && return 0; format_error "No line matches" "needle" "${1}" "actual" "${output-}" | flunk; return 1; }
assert_any_line_matches_case() { _echo_any_line matches 1 "${1?}" && return 0; format_error "No line matches" "needle" "${1}" "actual" "${output-}" | flunk; return 1; }
assert_no_line_matches() { _echo_any_line matches 0 "${1?}" && { format_error "Line unexpectedly matches" "needle" "${1}" | flunk; return 1; }; }
assert_no_line_matches_case() { _echo_any_line matches 1 "${1?}" && { format_error "Line unexpectedly matches" "needle" "${1}" | flunk; return 1; }; }
assert_any_line_matches_format() { _echo_any_line format 0 "${1?}" && return 0; format_error "No line matches" "needle" "${1}" "actual" "${output-}" | flunk; return 1; }
assert_any_line_matches_format_case() { _echo_any_line format 1 "${1?}" && return 0; format_error "No line matches" "needle" "${1}" "actual" "${output-}" | flunk; return 1; }
assert_no_line_matches_format() { _echo_any_line format 0 "${1?}" && { format_error "Line unexpectedly matches" "needle" "${1}" | flunk; return 1; }; }
assert_no_line_matches_format_case() { _echo_any_line format 1 "${1?}" && { format_error "Line unexpectedly matches" "needle" "${1}" | flunk; return 1; }; }

##
# Count the lines, optionally those satisfying a needle.
#
# Arguments:
#   1. kind: empty for all lines, else contains|matches|format.
#   2. sensitive: 1 for case-sensitive, 0 for case-insensitive.
#   3. needle: Needle, read per kind. Empty when kind is empty.
#
# Outputs:
#   STDOUT: The count.
##
_echo_count_lines() {
  local kind="${1}"
  local sensitive="${2}"
  local needle="${3}"
  local count=0
  local line

  for line in ${lines[@]+"${lines[@]}"}; do
    if [ -z "${kind}" ] || string_match "${kind}" "${sensitive}" "${line}" "${needle}"; then
      count=$((count + 1))
    fi
  done

  printf '%s\n' "${count}"
}

_echo_assert_line_count() {
  local want_equal="${1}"
  local expected="${2}"
  local kind="${3}"
  local sensitive="${4}"
  local needle="${5}"
  local actual
  actual="$(_echo_count_lines "${kind}" "${sensitive}" "${needle}")"

  if [ "${want_equal}" = "1" ] && [ "${actual}" -ne "${expected}" ]; then
    format_error "Line count differs" "expected" "${expected}" "actual" "${actual}" | flunk
    return 1
  fi

  if [ "${want_equal}" = "0" ] && [ "${actual}" -eq "${expected}" ]; then
    format_error "Line count unexpectedly equals" "actual" "${actual}" | flunk
    return 1
  fi
}

assert_line_count() { _echo_assert_line_count 1 "${1?}" "" 0 ""; }
assert_line_count_not() { _echo_assert_line_count 0 "${1?}" "" 0 ""; }
assert_line_count_contains() { _echo_assert_line_count 1 "${1?}" contains 0 "${2?}"; }
assert_line_count_contains_case() { _echo_assert_line_count 1 "${1?}" contains 1 "${2?}"; }
assert_line_count_not_contains() { _echo_assert_line_count 0 "${1?}" contains 0 "${2?}"; }
assert_line_count_not_contains_case() { _echo_assert_line_count 0 "${1?}" contains 1 "${2?}"; }
assert_line_count_matches() { _echo_assert_line_count 1 "${1?}" matches 0 "${2?}"; }
assert_line_count_matches_case() { _echo_assert_line_count 1 "${1?}" matches 1 "${2?}"; }
assert_line_count_not_matches() { _echo_assert_line_count 0 "${1?}" matches 0 "${2?}"; }
assert_line_count_not_matches_case() { _echo_assert_line_count 0 "${1?}" matches 0 "${2?}"; }
assert_line_count_matches_format() { _echo_assert_line_count 1 "${1?}" format 0 "${2?}"; }
assert_line_count_matches_format_case() { _echo_assert_line_count 1 "${1?}" format 1 "${2?}"; }
assert_line_count_not_matches_format() { _echo_assert_line_count 0 "${1?}" format 0 "${2?}"; }
assert_line_count_not_matches_format_case() { _echo_assert_line_count 0 "${1?}" format 0 "${2?}"; }
