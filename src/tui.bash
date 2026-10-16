#!/usr/bin/env bash
##
# @file
# TUI driver: feed scripted answers to an interactive script, assert prompts.
#
# Answers go to STDIN, one per line; the transcript is kept for assertions.
# A deadline bounds hung scripts. Needs 'timeout' where available — without it
# the script simply runs to completion (documented, macOS-safe).
#

##
# Run an interactive script with scripted answers.
#
# Arguments:
#   1. script: Executable script to drive.
#   2+. answers: One STDIN line each.
#
# Globals set:
#   ECHO_TUI_OUTPUT: Full transcript.
#   ECHO_TUI_STATUS: Script exit status.
#   ECHO_TUI_TIMEOUT: Optional whole-second deadline. Empty disables it.
##
tui_run() {
  if [ "$#" -lt 1 ]; then
    flunk "tui_run requires a script."
    return 1
  fi

  local script="${1}"
  shift

  if [ ! -x "${script}" ]; then
    flunk "TUI script is not executable: ${script}."
    return 1
  fi

  local input
  input="$(mktemp)" || return 1
  printf '%s\n' "$@" > "${input}"

  local deadline="${ECHO_TUI_TIMEOUT-}"
  local runner=()

  if [ -n "${deadline}" ] && command -v timeout >/dev/null 2>&1; then
    runner=(timeout "${deadline}")
  fi

  ECHO_TUI_OUTPUT="$("${runner[@]}" "${script}" < "${input}" 2>&1)"
  ECHO_TUI_STATUS="$?"
  export ECHO_TUI_OUTPUT ECHO_TUI_STATUS
  rm -f "${input}"

  if [ -n "${deadline}" ] && [ "${ECHO_TUI_STATUS}" -eq 124 ] && [ "${#runner[@]}" -gt 0 ]; then
    format_error "TUI script hit the deadline" "script" "${script}" "deadline" "${deadline} second(s)" "output" "${ECHO_TUI_OUTPUT}" | flunk
    return 1
  fi
}

##
# Assert every expected prompt appears in the transcript, in order.
#
# Arguments:
#   1+. prompts: Substrings, expected in order.
##
tui_assert_prompts() {
  if [ "$#" -eq 0 ]; then flunk "tui_assert_prompts requires at least one prompt."; return 1; fi
  if [ -z "${ECHO_TUI_OUTPUT-}" ]; then flunk "No TUI transcript; run tui_run first."; return 1; fi

  local rest="${ECHO_TUI_OUTPUT}"
  local prompt

  for prompt in "$@"; do
    case "${rest}" in
      *"${prompt}"*)
        rest="${rest#*"${prompt}"}"
        ;;
      *)
        format_error "Prompt missing from transcript" "prompt" "${prompt}" "transcript" "${ECHO_TUI_OUTPUT}" | flunk
        return 1
        ;;
    esac
  done
}

tui_assert_prompts_case() { tui_assert_prompts "$@"; }
