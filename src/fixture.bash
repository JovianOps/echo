#!/usr/bin/env bash
##
# @file
# Fixtures: sandboxes plus a plain-text archive of whole directory trees.
#
# Archive format, one entry per file:
#
#   @@ relative/path/to/file
#   <content lines verbatim>
#
# Entries are separated by the next '@@ ' line. Paths are relative to the
# archived root and sorted. Text files only; compare binaries with
# assert_binary_files_equal instead.
#

##
# Copy a tree into a fresh sandbox, excluding version control.
#
# Arguments:
#   1. source: Directory to copy.
#   2. name: Sandbox name. Default 'sandbox'.
#
# Outputs:
#   STDOUT: The sandbox path.
##
fixture_export_codebase() {
  if [ "$#" -lt 1 ]; then flunk "fixture_export_codebase requires a source."; return 1; fi
  local dest
  dest="$(fixture_prepare_dir "${2-sandbox}")" || return 1
  (cd "${1}" && tar cf - --exclude=.git .) | (cd "${dest}" && tar xf -)
  printf '%s\n' "${dest}"
}

##
# Create an empty sandbox directory.
#
# Arguments:
#   1. name: Sandbox name. Default 'sandbox'.
#
# Outputs:
#   STDOUT: The sandbox path.
##
fixture_prepare_dir() {
  local base="${BATS_TEST_TMPDIR:-${TMPDIR:-/tmp}}"
  local dest="${base}/${1-sandbox}"

  if [ -e "${dest}" ]; then
    flunk "Sandbox already exists: ${dest}."
    return 1
  fi

  mkdir -p "${dest}"
  printf '%s\n' "${dest}"
}

fixture_create_dir() { fixture_prepare_dir "$@"; }

##
# Serialize a directory into the archive format.
#
# Arguments:
#   1. dir: Directory to dump.
#
# Outputs:
#   STDOUT: The archive.
##
fixture_dump_dir() {
  if [ "$#" -ne 1 ]; then flunk "fixture_dump_dir requires a directory."; return 1; fi
  assert_dir_exists "${1}" || return 1
  local file
  local relative

  while IFS= read -r file; do
    relative="${file#"${1}"/}"
    printf '@@ %s\n' "${relative}"
    cat -- "${1}/${relative}"
  done < <(cd "${1}" && find . -mindepth 1 -type f | LC_ALL=C sort | sed 's|^\./||')
}

##
# Assert a directory matches an archive, with per-file diffs.
#
# Arguments:
#   1. dir: Directory under test.
#   2. archive: Expected archive text.
##
fixture_assert_dir() {
  if [ "$#" -ne 2 ]; then flunk "fixture_assert_dir requires a directory and an archive."; return 1; fi
  assert_dir_exists "${1}" || return 1

  local expected
  expected="$(mktemp)" || return 1
  printf '%s\n' "${2}" > "${expected}"

  local actual
  actual="$(mktemp)" || { rm -f "${expected}"; return 1; }
  fixture_dump_dir "${1}" > "${actual}"

  if ! cmp -s -- "${expected}" "${actual}"; then
    local report
    report="$(diff -u -- "${expected}" "${actual}" || true)"
    rm -f "${expected}" "${actual}"
    format_error "Directory differs from archive" "directory" "${1}" "diff" "${report}" | flunk
    return 1
  fi

  rm -f "${expected}" "${actual}"
}
