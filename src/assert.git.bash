#!/usr/bin/env bash
##
# @file
# Git repository assertions.
#

_echo_git() {
  git -C "${1}" "${@:2}"
}

assert_git_repo() {
  if [ "$#" -ne 1 ]; then flunk "assert_git_repo requires a path."; return 1; fi
  if ! _echo_git "${1}" rev-parse --git-dir >/dev/null 2>&1; then
    format_error "Not a git repository" "path" "${1}" | flunk
    return 1
  fi
}

assert_not_git_repo() {
  if [ "$#" -ne 1 ]; then flunk "assert_not_git_repo requires a path."; return 1; fi
  if _echo_git "${1}" rev-parse --git-dir >/dev/null 2>&1; then
    format_error "Unexpectedly a git repository" "path" "${1}" | flunk
    return 1
  fi
}

assert_git_not_repo() { assert_not_git_repo "$@"; }

_echo_git_tracked() {
  _echo_git "${1}" ls-files --error-unmatch -- "${2}" >/dev/null 2>&1
}

assert_git_file_tracked() {
  if [ "$#" -ne 2 ]; then flunk "assert_git_file_tracked requires a repository and a file."; return 1; fi
  assert_git_repo "${1}" || return 1
  if ! _echo_git_tracked "${1}" "${2}"; then
    format_error "File is not tracked" "repository" "${1}" "file" "${2}" | flunk
    return 1
  fi
}
assert_git_file_is_tracked() { assert_git_file_tracked "$@"; }

assert_git_file_not_tracked() {
  if [ "$#" -ne 2 ]; then flunk "assert_git_file_not_tracked requires a repository and a file."; return 1; fi
  assert_git_repo "${1}" || return 1
  if _echo_git_tracked "${1}" "${2}"; then
    format_error "File is unexpectedly tracked" "repository" "${1}" "file" "${2}" | flunk
    return 1
  fi
}
assert_git_file_is_not_tracked() { assert_git_file_not_tracked "$@"; }

assert_git_clean() {
  if [ "$#" -ne 1 ]; then flunk "assert_git_clean requires a path."; return 1; fi
  assert_git_repo "${1}" || return 1
  if [ -n "$(_echo_git "${1}" status --porcelain)" ]; then
    format_error "Repository is not clean" "repository" "${1}" "status" "$(_echo_git "${1}" status --porcelain)" | flunk
    return 1
  fi
}

assert_git_not_clean() {
  if [ "$#" -ne 1 ]; then flunk "assert_git_not_clean requires a path."; return 1; fi
  assert_git_repo "${1}" || return 1
  if [ -z "$(_echo_git "${1}" status --porcelain)" ]; then
    format_error "Repository is unexpectedly clean" "repository" "${1}" | flunk
    return 1
  fi
}
