#!/usr/bin/env bash
##
# @file
# Small file utilities: touch with parents, trim, dotenv reading, backup.
#

##
# Create parent directories and touch a file.
#
# Arguments:
#   1. path: File to create.
##
file_mktouch() {
  if [ "$#" -ne 1 ]; then flunk "file_mktouch requires a path."; return 1; fi
  mkdir -p "$(dirname "${1}")" && touch "${1}"
}

mktouch() { file_mktouch "$@"; }

##
# Strip trailing whitespace from every line of a file, in place.
#
# Arguments:
#   1. path: File to trim.
##
file_trim() {
  if [ "$#" -ne 1 ]; then flunk "file_trim requires a path."; return 1; fi
  assert_file_exists "${1}" || return 1
  local tmp
  tmp="$(mktemp)" || return 1
  sed -e 's/[[:space:]]*$//' "${1}" > "${tmp}" && cat "${tmp}" > "${1}"
  rm -f "${tmp}"
}

trim_file() { file_trim "$@"; }

##
# Export KEY=VALUE lines from a dotenv file, ignoring comments and blanks.
#
# Arguments:
#   1. path: dotenv file.
##
file_read_env() {
  if [ "$#" -ne 1 ]; then flunk "file_read_env requires a path."; return 1; fi
  assert_file_exists "${1}" || return 1
  set -a
  # shellcheck disable=SC1090
  . "${1}"
  set +a
}

read_env() { file_read_env "$@"; }

##
# Path where a backup of a file lives.
#
# Arguments:
#   1. path: File to back up.
#
# Outputs:
#   STDOUT: The backup path.
##
file_backup_path() {
  printf '%s.echo-backup\n' "${1?}"
}

##
# Append a variable assignment to a file, backing it up first.
#
# Arguments:
#   1. path: File to extend.
#   2. assignment: Line like 'KEY=value' to append.
##
file_add_var() {
  if [ "$#" -ne 2 ]; then flunk "file_add_var requires a path and an assignment."; return 1; fi
  assert_file_exists "${1}" || return 1
  cp -- "${1}" "$(file_backup_path "${1}")"
  printf '%s\n' "${2}" >> "${1}"
}

add_var_to_file() { file_add_var "$@"; }

##
# Restore a file from its backup.
#
# Arguments:
#   1. path: File to restore.
##
file_restore() {
  if [ "$#" -ne 1 ]; then flunk "file_restore requires a path."; return 1; fi
  local backup
  backup="$(file_backup_path "${1}")"
  assert_file_exists "${backup}" || return 1
  cat -- "${backup}" > "${1}"
  rm -f "${backup}"
}

restore_file() { file_restore "$@"; }
