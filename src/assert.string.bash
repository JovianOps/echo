#!/usr/bin/env bash
##
# @file
# String assertions: empty, equal, literal, regex and format matching.
#
# Every verb comes in four forms: plain (case-insensitive), '_case'
# (case-sensitive), 'not_' (absent) and 'not_..._case'. Case-insensitive is
# the historic default, so 'assert_output_contains "ABC"' matches 'abc'.
#

##
# Assert a value is empty.
#
# Arguments:
#   1. actual: Value that must be empty.
##
assert_empty() {
  if [ "$#" -ne 1 ]; then
    flunk "assert_empty requires exactly one argument."
    return 1
  fi

  if [ -n "${1}" ]; then
    format_error "Value is not empty" "actual" "${1}" | flunk
    return 1
  fi
}

##
# Assert a value is not empty.
#
# Arguments:
#   1. actual: Value that must not be empty.
##
assert_not_empty() {
  if [ "$#" -ne 1 ]; then
    flunk "assert_not_empty requires exactly one argument."
    return 1
  fi

  if [ -z "${1}" ]; then
    format_error "Value is empty" | flunk
    return 1
  fi
}

##
# Assert two values are exactly equal.
#
# Arguments:
#   1. expected: Expected value.
#   2. actual: Actual value.
##
assert_equal() {
  if [ "$#" -ne 2 ]; then
    flunk "assert_equal requires an expected and an actual value."
    return 1
  fi

  if [ "${1}" != "${2}" ]; then
    format_error "Values differ" "expected" "${1}" "actual" "${2}" | flunk
    return 1
  fi
}

##
# Lowercase a value for case-insensitive comparison.
#
# Arguments:
#   1. value: Value to fold.
#
# Outputs:
#   STDOUT: The folded value.
##
_echo_fold() {
  printf '%s' "${1}" | tr '[:upper:]' '[:lower:]'
}

##
# Core needle assertion shared by every verb and family.
#
# Arguments:
#   1. kind: contains|starts_with|ends_with|matches|format.
#   2. want: 1 when the needle must be found, 0 when it must be absent.
#   3. sensitive: 1 for case-sensitive, 0 for case-insensitive.
#   4. noun: What the subject is ('output', 'file content', ...).
#   5. subject: Value under test.
#   6. needle: Needle, read per kind.
##
_echo_assert_needle() {
  local kind="${1}"
  local want="${2}"
  local sensitive="${3}"
  local noun="${4}"
  local subject="${5}"
  local needle="${6}"
  local found=0
  local pattern=""

  case "${kind}" in
    contains)
      if [ "${sensitive}" = "1" ]; then
        case "${subject}" in *"${needle}"*) found=1 ;; esac
      else
        case "$(_echo_fold "${subject}")" in *"$(_echo_fold "${needle}")"*) found=1 ;; esac
      fi
      ;;
    starts_with)
      if [ "${sensitive}" = "1" ]; then
        case "${subject}" in "${needle}"*) found=1 ;; esac
      else
        case "$(_echo_fold "${subject}")" in "$(_echo_fold "${needle}")"*) found=1 ;; esac
      fi
      ;;
    ends_with)
      if [ "${sensitive}" = "1" ]; then
        case "${subject}" in *"${needle}") found=1 ;; esac
      else
        case "$(_echo_fold "${subject}")" in *"$(_echo_fold "${needle}")") found=1 ;; esac
      fi
      ;;
    matches | format)
      if [ "${kind}" = "format" ]; then
        pattern="$(string_format_to_regex "${needle}")" || return 1
      else
        pattern="${needle}"
      fi

      if [ "${sensitive}" = "1" ]; then
        printf '%s' "${subject}" | grep -E -q -- "${pattern}" && found=1
      else
        printf '%s' "${subject}" | grep -E -i -q -- "${pattern}" && found=1
      fi
      ;;
  esac

  if [ "${want}" = "1" ] && [ "${found}" = "0" ]; then
    format_error "Needle not found in ${noun}" "needle" "${needle}" "actual" "${subject}" | flunk
    return 1
  fi

  if [ "${want}" = "0" ] && [ "${found}" = "1" ]; then
    format_error "Needle unexpectedly found in ${noun}" "needle" "${needle}" "actual" "${subject}" | flunk
    return 1
  fi
}

##
# Assert a string contains a needle, and the negated and case forms.
##
assert_string_contains() { _echo_assert_needle contains 1 0 "string" "${1?}" "${2?}"; }
assert_string_contains_case() { _echo_assert_needle contains 1 1 "string" "${1?}" "${2?}"; }
assert_string_not_contains() { _echo_assert_needle contains 0 0 "string" "${1?}" "${2?}"; }
assert_string_not_contains_case() { _echo_assert_needle contains 0 1 "string" "${1?}" "${2?}"; }

##
# Assert a string matches a needle, and the negated and case forms.
##
assert_string_matches() { _echo_assert_needle matches 1 0 "string" "${1?}" "${2?}"; }
assert_string_matches_case() { _echo_assert_needle matches 1 1 "string" "${1?}" "${2?}"; }
assert_string_not_matches() { _echo_assert_needle matches 0 0 "string" "${1?}" "${2?}"; }
assert_string_not_matches_case() { _echo_assert_needle matches 0 1 "string" "${1?}" "${2?}"; }

##
# Assert a string matches a format needle, and the negated and case forms.
##
assert_string_matches_format() { _echo_assert_needle format 1 0 "string" "${1?}" "${2?}"; }
assert_string_matches_format_case() { _echo_assert_needle format 1 1 "string" "${1?}" "${2?}"; }
assert_string_not_matches_format() { _echo_assert_needle format 0 0 "string" "${1?}" "${2?}"; }
assert_string_not_matches_format_case() { _echo_assert_needle format 0 1 "string" "${1?}" "${2?}"; }

##
# Assert a string starts or ends with a needle, and the negated and case forms.
##
assert_string_starts_with() { _echo_assert_needle starts_with 1 0 "string" "${1?}" "${2?}"; }
assert_string_starts_with_case() { _echo_assert_needle starts_with 1 1 "string" "${1?}" "${2?}"; }
assert_string_not_starts_with() { _echo_assert_needle starts_with 0 0 "string" "${1?}" "${2?}"; }
assert_string_not_starts_with_case() { _echo_assert_needle starts_with 0 1 "string" "${1?}" "${2?}"; }
assert_string_ends_with() { _echo_assert_needle ends_with 1 0 "string" "${1?}" "${2?}"; }
assert_string_ends_with_case() { _echo_assert_needle ends_with 1 1 "string" "${1?}" "${2?}"; }
assert_string_not_ends_with() { _echo_assert_needle ends_with 0 0 "string" "${1?}" "${2?}"; }
assert_string_not_ends_with_case() { _echo_assert_needle ends_with 0 1 "string" "${1?}" "${2?}"; }

##
# Report whether a subject matches a needle, printing nothing.
#
# Arguments:
#   1. kind: contains|matches|format.
#   2. sensitive: 1 for case-sensitive, 0 for case-insensitive.
#   3. subject: Value under test.
#   4. needle: Needle, read per kind.
#
# Returns:
#   0 on match, 1 otherwise.
##
string_match() {
  local kind="${1}"
  local sensitive="${2}"
  local subject="${3}"
  local needle="${4}"

  case "${kind}" in
    contains)
      if [ "${sensitive}" = "1" ]; then
        case "${subject}" in *"${needle}"*) return 0 ;; *) return 1 ;; esac
      else
        case "$(_echo_fold "${subject}")" in *"$(_echo_fold "${needle}")"*) return 0 ;; *) return 1 ;; esac
      fi
      ;;
    matches | format)
      local pattern="${needle}"

      if [ "${kind}" = "format" ]; then
        pattern="$(string_format_to_regex "${needle}")" || return 1
      fi

      if [ "${sensitive}" = "1" ]; then
        printf '%s' "${subject}" | grep -E -q -- "${pattern}"
      else
        printf '%s' "${subject}" | grep -E -i -q -- "${pattern}"
      fi
      ;;
    *)
      flunk "Unknown match kind '${kind}'."
      return 1
      ;;
  esac
}

##
# Translate a format string into an extended regular expression.
#
# Placeholders: '%d' digits, '%f' number with optional fraction, '%s'
# non-whitespace run, '%%' a literal percent. Everything else is literal.
#
# Arguments:
#   1. format: Format string.
#
# Outputs:
#   STDOUT: The equivalent pattern.
##
string_format_to_regex() {
  local format="${1}"
  local regex=""
  local index=0
  local char

  while [ "${index}" -lt "${#format}" ]; do
    char="${format:index:1}"

    if [ "${char}" != "%" ]; then
      case "${char}" in
        '\\' | '.' | '|' | '$' | '(' | ')' | '[' | ']' | '{' | '}' | '?' | '+' | '*' | '^')
          regex="${regex}\\${char}"
          ;;
        *)
          regex="${regex}${char}"
          ;;
      esac

      index=$((index + 1))
      continue
    fi

    case "${format:index+1:1}" in
      d) regex="${regex}[0-9]+" ;;
      f) regex="${regex}[0-9]+(\\.[0-9]+)?" ;;
      s) regex="${regex}[^[:space:]]+" ;;
      %) regex="${regex}%" ;;
      *)
        flunk "Unknown format placeholder '%${format:index+1:1}'. Use '%d', '%f', '%s' or '%%'."
        return 1
        ;;
    esac

    index=$((index + 2))
  done

  printf '%s\n' "${regex}"
}

##
# Print a random alphanumeric string.
#
# Arguments:
#   1. length: Characters to print. Default 8.
#
# Outputs:
#   STDOUT: The random string.
##
string_random() {
  local length="${1:-8}"
  local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local result=""
  local i

  for ((i = 0; i < length; i++)); do
    result="${result}${chars:RANDOM % ${#chars}:1}"
  done

  printf '%s\n' "${result}"
}

##
# Legacy aliases kept for compatibility.
##
assert_contains() { assert_string_contains "$@"; }
assert_not_contains() { assert_string_not_contains "$@"; }
random_string() { string_random "$@"; }
