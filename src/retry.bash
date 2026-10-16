#!/usr/bin/env bash
##
# @file
# Retry: run a command until it succeeds, bounded by attempts and deadline.
#
# Globals set on every run:
#   ECHO_RETRY_ATTEMPTS: Attempts used.
#   ECHO_RETRY_OUTPUT: Output of the last attempt.
#   ECHO_RETRY_ELAPSED: Whole seconds spent.
#   ECHO_RETRY_TIMEOUT: Optional whole-second deadline. Empty disables it.
#

##
# Retry a command.
#
# Arguments:
#   1. attempts: Positive integer attempt count.
#   2. delay: Non-negative seconds between attempts (fractions allowed).
#   3+. command: Command and arguments.
##
retry_run() {
  if [ "$#" -lt 3 ]; then
    flunk "An attempt count, a delay and a command are required."
    return 1
  fi

  local attempts="${1}"
  local delay="${2}"
  shift 2

  case "${attempts}" in
    '' | *[!0-9]* | 0) flunk "Attempt count '${attempts}' must be a positive integer."; return 1 ;;
  esac

  case "${delay}" in
    '' | *[!0-9.]* | .* | *.) flunk "Delay '${delay}' must be a non-negative number."; return 1 ;;
  esac

  if [ -z "${1-}" ]; then
    flunk "Command name must not be empty."
    return 1
  fi

  if ! command -v "${1}" >/dev/null 2>&1; then
    flunk "Command '${1}' is not a valid command."
    return 1
  fi

  local timeout="${ECHO_RETRY_TIMEOUT-}"

  case "${timeout}" in
    '') ;;
    *[!0-9]*) flunk "Timeout '${timeout}' must be a whole number of seconds."; return 1 ;;
  esac

  ECHO_RETRY_ATTEMPTS=0
  ECHO_RETRY_OUTPUT=""
  ECHO_RETRY_ELAPSED=0
  export ECHO_RETRY_ATTEMPTS ECHO_RETRY_OUTPUT ECHO_RETRY_ELAPSED

  local start="${SECONDS}"
  local last_status=0
  local deadline_hit=0

  while true; do
    ECHO_RETRY_ATTEMPTS=$((ECHO_RETRY_ATTEMPTS + 1))

    last_status=0
    ECHO_RETRY_OUTPUT="$("$@" 2>&1)" || last_status="$?"
    ECHO_RETRY_ELAPSED=$((SECONDS - start))

    if [ "${last_status}" -eq 0 ]; then
      if [ "${ECHO_RETRY_ATTEMPTS}" -gt 1 ]; then
        echo "Retried: '${1}' succeeded on attempt ${ECHO_RETRY_ATTEMPTS} of ${attempts} after ${ECHO_RETRY_ELAPSED} second(s)." >&3
      fi

      return 0
    fi

    if [ "${ECHO_RETRY_ATTEMPTS}" -ge "${attempts}" ]; then
      break
    fi

    if [ -n "${timeout}" ] && [ "${ECHO_RETRY_ELAPSED}" -ge "${timeout}" ]; then
      deadline_hit=1
      break
    fi

    sleep "${delay}"
  done

  local bound="${attempts} attempt(s)"

  if [ "${deadline_hit}" = "1" ]; then
    bound="the ${timeout} second deadline"
  fi

  format_error "Command did not succeed within the retry limit" \
    "command" "${1}" \
    "limit" "${bound}" \
    "attempts" "${ECHO_RETRY_ATTEMPTS}" \
    "elapsed" "${ECHO_RETRY_ELAPSED} second(s)" \
    "last status" "${last_status}" \
    "last output" "${ECHO_RETRY_OUTPUT}" | flunk
}
