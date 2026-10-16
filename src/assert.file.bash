#!/usr/bin/env bash
##
# @file
# File and directory assertions: presence, mode, content, equality.
#

assert_file_exists() {
  if [ "$#" -ne 1 ]; then flunk "assert_file_exists requires a path."; return 1; fi
  if [ ! -f "${1}" ]; then
    format_error "File does not exist" "path" "${1}" | flunk
    return 1
  fi
}

assert_file_not_exists() {
  if [ "$#" -ne 1 ]; then flunk "assert_file_not_exists requires a path."; return 1; fi
  if [ -e "${1}" ]; then
    format_error "File unexpectedly exists" "path" "${1}" | flunk
    return 1
  fi
}

assert_dir_exists() {
  if [ "$#" -ne 1 ]; then flunk "assert_dir_exists requires a path."; return 1; fi
  if [ ! -d "${1}" ]; then
    format_error "Directory does not exist" "path" "${1}" | flunk
    return 1
  fi
}

assert_dir_not_exists() {
  if [ "$#" -ne 1 ]; then flunk "assert_dir_not_exists requires a path."; return 1; fi
  if [ -e "${1}" ]; then
    format_error "Path unexpectedly exists" "path" "${1}" | flunk
    return 1
  fi
}

assert_dir_empty() {
  if [ "$#" -ne 1 ]; then flunk "assert_dir_empty requires a path."; return 1; fi
  assert_dir_exists "${1}" || return 1
  if [ -n "$(ls -A "${1}")" ]; then
    format_error "Directory is not empty" "path" "${1}" | flunk
    return 1
  fi
}

assert_dir_not_empty() {
  if [ "$#" -ne 1 ]; then flunk "assert_dir_not_empty requires a path."; return 1; fi
  assert_dir_exists "${1}" || return 1
  if [ -z "$(ls -A "${1}")" ]; then
    format_error "Directory is empty" "path" "${1}" | flunk
    return 1
  fi
}

assert_symlink_exists() {
  if [ "$#" -ne 1 ]; then flunk "assert_symlink_exists requires a path."; return 1; fi
  if [ ! -L "${1}" ]; then
    format_error "Symlink does not exist" "path" "${1}" | flunk
    return 1
  fi
}

assert_symlink_not_exists() {
  if [ "$#" -ne 1 ]; then flunk "assert_symlink_not_exists requires a path."; return 1; fi
  if [ -L "${1}" ]; then
    format_error "Symlink unexpectedly exists" "path" "${1}" | flunk
    return 1
  fi
}

##
# Assert the permission bits of a file.
#
# Arguments:
#   1. path: File to inspect.
#   2. mode: Expected octal mode, e.g. '644'.
##
assert_file_mode() {
  if [ "$#" -ne 2 ]; then flunk "assert_file_mode requires a path and a mode."; return 1; fi
  assert_file_exists "${1}" || return 1
  local actual=""

  if stat -c '%a' "${1}" >/dev/null 2>&1; then
    actual="$(stat -c '%a' "${1}")"
  else
    actual="$(stat -f '%Lp' "${1}")"
  fi

  if [ "${actual}" != "${2}" ]; then
    format_error "File mode differs" "path" "${1}" "expected" "${2}" "actual" "${actual}" | flunk
    return 1
  fi
}

##
# Read a file or fail when it cannot be read.
##
_echo_file_content() {
  if [ ! -f "${1}" ]; then
    flunk "File does not exist: ${1}."
    return 1
  fi

  cat -- "${1}"
}

assert_file_contains() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle contains 1 0 "file ${1}" "${c}" "${2?}"; }
assert_file_contains_case() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle contains 1 1 "file ${1}" "${c}" "${2?}"; }
assert_file_not_contains() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle contains 0 0 "file ${1}" "${c}" "${2?}"; }
assert_file_not_contains_case() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle contains 0 1 "file ${1}" "${c}" "${2?}"; }
assert_file_matches() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle matches 1 0 "file ${1}" "${c}" "${2?}"; }
assert_file_matches_case() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle matches 1 1 "file ${1}" "${c}" "${2?}"; }
assert_file_not_matches() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle matches 0 0 "file ${1}" "${c}" "${2?}"; }
assert_file_not_matches_case() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle matches 0 1 "file ${1}" "${c}" "${2?}"; }
assert_file_matches_format() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle format 1 0 "file ${1}" "${c}" "${2?}"; }
assert_file_matches_format_case() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle format 1 1 "file ${1}" "${c}" "${2?}"; }
assert_file_not_matches_format() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle format 0 0 "file ${1}" "${c}" "${2?}"; }
assert_file_not_matches_format_case() { local c; c="$(_echo_file_content "${1?}")" || return 1; _echo_assert_needle format 0 1 "file ${1}" "${c}" "${2?}"; }

##
# Whether any file under a directory contains a string.
##
_echo_dir_grep() {
  local dir="${1}"
  local case_flag="${2}"
  local needle="${3}"

  assert_dir_exists "${dir}" || return 1

  if [ "${case_flag}" = "1" ]; then
    grep -r -l -- "${needle}" "${dir}" 2>/dev/null | grep -q .
  else
    grep -r -i -l -- "${needle}" "${dir}" 2>/dev/null | grep -q .
  fi
}

assert_dir_contains_string() { _echo_dir_grep "${1?}" 0 "${2?}" && return 0; format_error "No file under directory contains" "directory" "${1}" "needle" "${2}" | flunk; return 1; }
assert_dir_contains_string_case() { _echo_dir_grep "${1?}" 1 "${2?}" && return 0; format_error "No file under directory contains" "directory" "${1}" "needle" "${2}" | flunk; return 1; }
assert_dir_not_contains_string() { _echo_dir_grep "${1?}" 0 "${2?}" && { format_error "File under directory unexpectedly contains" "directory" "${1}" "needle" "${2}" | flunk; return 1; }; }
assert_dir_not_contains_string_case() { _echo_dir_grep "${1?}" 1 "${2?}" && { format_error "File under directory unexpectedly contains" "directory" "${1}" "needle" "${2}" | flunk; return 1; }; }

##
# Whether any relative path under a directory matches a pattern.
##
_echo_dir_names() {
  (cd "${1}" && find . -mindepth 1 | LC_ALL=C sort)
}

_echo_dir_name_match() {
  local dir="${1}"
  local case_flag="${2}"
  local pattern="${3}"
  local name

  assert_dir_exists "${dir}" || return 1

  while IFS= read -r name; do
    if [ "${case_flag}" = "1" ]; then
      printf '%s' "${name}" | grep -E -q -- "${pattern}" && return 0
    else
      printf '%s' "${name}" | grep -E -i -q -- "${pattern}" && return 0
    fi
  done < <(_echo_dir_names "${dir}")

  return 1
}

assert_dir_matches() { _echo_dir_name_match "${1?}" 0 "${2?}" && return 0; format_error "No path under directory matches" "directory" "${1}" "pattern" "${2}" | flunk; return 1; }
assert_dir_matches_case() { _echo_dir_name_match "${1?}" 1 "${2?}" && return 0; format_error "No path under directory matches" "directory" "${1}" "pattern" "${2}" | flunk; return 1; }
assert_dir_not_matches() { _echo_dir_name_match "${1?}" 0 "${2?}" && { format_error "Path under directory unexpectedly matches" "directory" "${1}" "pattern" "${2}" | flunk; return 1; }; }
assert_dir_not_matches_case() { _echo_dir_name_match "${1?}" 1 "${2?}" && { format_error "Path under directory unexpectedly matches" "directory" "${1}" "pattern" "${2}" | flunk; return 1; }; }

##
# Assert two files are byte-identical, with a diff on failure.
##
_echo_files_equal() {
  local squeeze="${1}"
  local expected="${2}"
  local actual="${3}"
  local left="${expected}"
  local right="${actual}"

  assert_file_exists "${expected}" || return 1
  assert_file_exists "${actual}" || return 1

  if [ "${squeeze}" = "1" ]; then
    left="$(mktemp)"
    right="$(mktemp)"
    tr -s '[:space:]' ' ' < "${expected}" > "${left}"
    tr -s '[:space:]' ' ' < "${actual}" > "${right}"
  fi

  if cmp -s -- "${left}" "${right}"; then
    [ "${squeeze}" = "1" ] && rm -f "${left}" "${right}"
    return 0
  fi

  local report
  report="$(diff -u -- "${left}" "${right}" || true)"
  [ "${squeeze}" = "1" ] && rm -f "${left}" "${right}"
  format_error "Files differ" "expected" "${expected}" "actual" "${actual}" "diff" "${report}" | flunk
  return 1
}

##
# Assert two files differ at the byte level.
##
_echo_files_not_equal() {
  local squeeze="${1}"
  local first="${2}"
  local second="${3}"

  assert_file_exists "${first}" || return 1
  assert_file_exists "${second}" || return 1

  if [ "${squeeze}" = "1" ]; then
    local a b
    a="$(mktemp)"
    b="$(mktemp)"
    tr -s '[:space:]' ' ' < "${first}" > "${a}"
    tr -s '[:space:]' ' ' < "${second}" > "${b}"
    first="${a}"
    second="${b}"
  fi

  if cmp -s -- "${first}" "${second}"; then
    [ "${squeeze}" = "1" ] && rm -f "${first}" "${second}"
    format_error "Files are unexpectedly identical" "first" "${2}" "second" "${3}" | flunk
    return 1
  fi

  [ "${squeeze}" = "1" ] && rm -f "${first}" "${second}"
}

assert_files_equal() { _echo_files_equal 0 "${1?}" "${2?}"; }
assert_files_equal_ignore_spaces() { _echo_files_equal 1 "${1?}" "${2?}"; }
assert_files_not_equal() { _echo_files_not_equal 0 "${1?}" "${2?}"; }
assert_files_not_equal_ignore_spaces() { _echo_files_not_equal 1 "${1?}" "${2?}"; }
assert_binary_files_equal() { _echo_files_equal 0 "${1?}" "${2?}"; }
assert_binary_files_not_equal() { _echo_files_not_equal 0 "${1?}" "${2?}"; }

##
# Assert two directory trees match recursively.
##
assert_dirs_equal() {
  if [ "$#" -ne 2 ]; then flunk "assert_dirs_equal requires two directories."; return 1; fi
  assert_dir_exists "${1}" || return 1
  assert_dir_exists "${2}" || return 1

  local report
  report="$(diff -r -- "${1}" "${2}" || true)"

  if [ -n "${report}" ]; then
    format_error "Directories differ" "expected" "${1}" "actual" "${2}" "diff" "${report}" | flunk
    return 1
  fi
}
