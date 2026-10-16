#!/usr/bin/env bash
##
# @file
# Command mocking: shims on PATH with per-call responses, arg-matched specs,
# strict mode, a sandbox, and a call log with sequence assertions.
#
# Layout per mock NAME under $ECHO_MOCK_DIR:
#   NAME.shim      The executable shim (copied from a template below).
#   NAME.log       One 'args' line per call, tab-separated from its status.
#   NAME.out       Default output. NAME.out.N overrides call N (1-based).
#   NAME.status    Default status (default 0). NAME.status.N overrides call N.
#   NAME.side.N    Shell snippet run on call N.
#   NAME.spec.N.{args,out,status,side,count,used}  Arg-matched specs.
#   forward.NAME   When present, unanswered calls exec the named real command.
#

##
# Create the mock bin dir and prepend it to PATH.
#
# Arguments:
#   1. dir: Directory to use. Default a fresh dir under BATS_TEST_TMPDIR.
#
# Globals set:
#   ECHO_MOCK_DIR: The mock state directory.
#   ECHO_MOCK_BIN: The directory prepended to PATH.
##
mock_setup() {
  ECHO_MOCK_DIR="${1:-$(mktemp -d "${BATS_TEST_TMPDIR:-${TMPDIR:-/tmp}}/echo-mock.XXXXXX")}"
  ECHO_MOCK_BIN="${ECHO_MOCK_DIR}/bin"
  mkdir -p "${ECHO_MOCK_BIN}"
  PATH="${ECHO_MOCK_BIN}:${PATH}"
  export ECHO_MOCK_DIR ECHO_MOCK_BIN PATH
}

setup_mock() { mock_setup "$@"; }

_echo_mock_state() {
  if [ -z "${ECHO_MOCK_DIR-}" ]; then
    flunk "Mock state missing; run mock_setup first."
    return 1
  fi
}

##
# Create a mock command.
#
# Arguments:
#   1. name: Command name to mock.
##
mock_create() {
  if [ "$#" -ne 1 ]; then flunk "mock_create requires a name."; return 1; fi
  _echo_mock_state || return 1

  cat > "${ECHO_MOCK_BIN}/${1}" <<'SHIM'
#!/usr/bin/env bash
name="$(basename "${0}")"
dir="${ECHO_MOCK_DIR}"
n="$([ -f "${dir}/${name}.calls" ] && cat "${dir}/${name}.calls" || echo 0)"
n=$((n + 1))
printf '%s' "${n}" > "${dir}/${name}.calls"
printf '%s\t%s\n' "$*" "0" >> "${dir}/${name}.log"

respond() {
  local file="${1}"
  [ -f "${file}" ] && cat -- "${file}"
}

status="0"
if [ -f "${dir}/${name}.status.${n}" ]; then
  status="$(cat "${dir}/${name}.status.${n}")"
elif [ -f "${dir}/${name}.status" ]; then
  status="$(cat "${dir}/${name}.status")"
fi

spec="$(ECHO_MOCK_NAME="${name}" ECHO_MOCK_ARGS="$*" ECHO_MOCK_N="${n}" ECHO_MOCK_DIR="${dir}" bash -c '
  name="${ECHO_MOCK_NAME}"; args="${ECHO_MOCK_ARGS}"; n="${ECHO_MOCK_N}"; dir="${ECHO_MOCK_DIR}"
  i=0
  while [ -f "${dir}/${name}.spec.${i}.args" ]; do
    if [ "$(cat "${dir}/${name}.spec.${i}.args")" = "${args}" ]; then
      used="$(cat "${dir}/${name}.spec.${i}.used" 2>/dev/null || echo 0)"
      count="$(cat "${dir}/${name}.spec.${i}.count" 2>/dev/null || echo 1)"
      if [ "${used}" -lt "${count}" ]; then
        echo "${i}"
        exit 0
      fi
    fi
    i=$((i + 1))
  done
  exit 1
' 2>/dev/null)" || true

if [ -n "${spec}" ]; then
  used="$(cat "${ECHO_MOCK_DIR}/${name}.spec.${spec}.used" 2>/dev/null || echo 0)"
  printf '%s' "$((used + 1))" > "${ECHO_MOCK_DIR}/${name}.spec.${spec}.used"
  [ -f "${ECHO_MOCK_DIR}/${name}.spec.${spec}.out" ] && respond "${ECHO_MOCK_DIR}/${name}.spec.${spec}.out"
  if [ -f "${ECHO_MOCK_DIR}/${name}.spec.${spec}.status" ]; then
    status="$(cat "${ECHO_MOCK_DIR}/${name}.spec.${spec}.status")"
  fi
  [ -f "${ECHO_MOCK_DIR}/${name}.spec.${spec}.side" ] && bash "${ECHO_MOCK_DIR}/${name}.spec.${spec}.side"
else
  answered=0
  [ -f "${dir}/${name}.out.${n}" ] && answered=1
  [ -f "${dir}/${name}.out" ] && answered=1
  [ -f "${dir}/${name}.status.${n}" ] && answered=1
  [ -f "${dir}/${name}.status" ] && answered=1
  [ -f "${dir}/${name}.side.${n}" ] && answered=1

  if [ "${answered}" = "0" ] && [ -f "${dir}/strict" ]; then
    echo "mock '${name}': no response for call ${n} in strict mode" >&2
    exit 1
  fi

  respond "${dir}/${name}.out.${n}"
  [ -f "${dir}/${name}.out.${n}" ] || respond "${dir}/${name}.out"
  [ -f "${dir}/${name}.side.${n}" ] && bash "${dir}/${name}.side.${n}"
fi

if [ -f "${dir}/forward.${name}" ] && [ -z "${spec}" ] && [ ! -f "${dir}/${name}.out" ] && [ ! -f "${dir}/${name}.out.${n}" ]; then
  exec "$(cat "${dir}/forward.${name}")" "$@"
fi

exit "${status}"
SHIM
  chmod +x "${ECHO_MOCK_BIN}/${1}"
  printf '0' > "${ECHO_MOCK_DIR}/${1}.calls"
  : > "${ECHO_MOCK_DIR}/${1}.log"
}

mock_command() { mock_create "$@"; }

##
# Set the default output, or the output of one call.
#
# Arguments:
#   1. name: Mock name.
#   2. output-or-n: Output text, or a 1-based call number followed by text.
##
mock_set_output() {
  if [ "$#" -lt 2 ]; then flunk "mock_set_output requires a name and output."; return 1; fi
  _echo_mock_state || return 1
  local name="${1}"
  shift
  if [ "$#" -gt 1 ] && [[ ${1} =~ ^[0-9]+$ ]]; then
    printf '%s' "${2}" > "${ECHO_MOCK_DIR}/${name}.out.${1}"
  else
    printf '%s' "${*}" > "${ECHO_MOCK_DIR}/${name}.out"
  fi
}

##
# Set the default status, or the status of one call.
##
mock_set_status() {
  if [ "$#" -lt 2 ]; then flunk "mock_set_status requires a name and a status."; return 1; fi
  _echo_mock_state || return 1
  local name="${1}"
  shift
  if [ "$#" -gt 1 ] && [[ ${1} =~ ^[0-9]+$ ]]; then
    printf '%s' "${2}" > "${ECHO_MOCK_DIR}/${name}.status.${1}"
  else
    printf '%s' "${1}" > "${ECHO_MOCK_DIR}/${name}.status"
  fi
}

##
# Set a shell snippet run as a side effect of one call.
#
# Arguments:
#   1. name: Mock name.
#   2. n: 1-based call number.
#   3+. snippet: Shell code.
##
mock_set_side_effect() {
  if [ "$#" -lt 3 ]; then flunk "mock_set_side_effect requires a name, a call number and code."; return 1; fi
  _echo_mock_state || return 1
  local name="${1}"
  local n="${2}"
  shift 2
  printf '%s' "${*}" > "${ECHO_MOCK_DIR}/${name}.side.${n}"
}

##
# Add an arg-matched spec; following setters target it until the next spec.
#
# Arguments:
#   1. name: Mock name.
#   2+. expected args: Exact expected argument string, joined with spaces.
##
mock_spec_add() {
  if [ "$#" -lt 1 ]; then flunk "mock_spec_add requires a name."; return 1; fi
  _echo_mock_state || return 1
  local name="${1}"
  shift
  local i=0
  while [ -f "${ECHO_MOCK_DIR}/${name}.spec.${i}.args" ]; do i=$((i + 1)); done
  printf '%s' "${*}" > "${ECHO_MOCK_DIR}/${name}.spec.${i}.args"
  printf '1' > "${ECHO_MOCK_DIR}/${name}.spec.${i}.count"
  printf '0' > "${ECHO_MOCK_DIR}/${name}.spec.${i}.used"
  printf '%s' "${i}" > "${ECHO_MOCK_DIR}/${name}.last-spec"
}

_echo_last_spec() {
  cat "${ECHO_MOCK_DIR}/${1}.last-spec" 2>/dev/null || echo 0
}

mock_spec_arg() { mock_spec_add "$@"; }

mock_spec_count() {
  if [ "$#" -ne 2 ]; then flunk "mock_spec_count requires a name and a count."; return 1; fi
  _echo_mock_state || return 1
  printf '%s' "${2}" > "${ECHO_MOCK_DIR}/${1}.spec.$(_echo_last_spec "${1}").count"
}

mock_spec_set_status() {
  if [ "$#" -ne 2 ]; then flunk "mock_spec_set_status requires a name and a status."; return 1; fi
  _echo_mock_state || return 1
  printf '%s' "${2}" > "${ECHO_MOCK_DIR}/${1}.spec.$(_echo_last_spec "${1}").status"
}

mock_spec_set_output() {
  if [ "$#" -ne 2 ]; then flunk "mock_spec_set_output requires a name and output."; return 1; fi
  _echo_mock_state || return 1
  printf '%s' "${2}" > "${ECHO_MOCK_DIR}/${1}.spec.$(_echo_last_spec "${1}").out"
}

mock_spec_set_side_effect() {
  if [ "$#" -lt 2 ]; then flunk "mock_spec_set_side_effect requires a name and code."; return 1; fi
  _echo_mock_state || return 1
  local name="${1}"
  shift
  printf '%s' "${*}" > "${ECHO_MOCK_DIR}/${name}.spec.$(_echo_last_spec "${name}").side"
}

##
# Forward unanswered calls to a real command.
#
# Arguments:
#   1. name: Mock name.
#   2. real: Real command path.
##
mock_set_forward() {
  if [ "$#" -ne 2 ]; then flunk "mock_set_forward requires a name and a real command."; return 1; fi
  _echo_mock_state || return 1
  printf '%s' "${2}" > "${ECHO_MOCK_DIR}/${1}.forward"
  printf '%s' "${2}" > "${ECHO_MOCK_DIR}/forward.${1}"
}

##
# Number of recorded calls.
##
mock_get_call_num() {
  if [ "$#" -ne 1 ]; then flunk "mock_get_call_num requires a name."; return 1; fi
  _echo_mock_state || return 1
  cat "${ECHO_MOCK_DIR}/${1}.calls" 2>/dev/null || echo 0
}

##
# Args of the Nth call (1-based).
##
mock_get_call_args() {
  if [ "$#" -ne 2 ]; then flunk "mock_get_call_args requires a name and a call number."; return 1; fi
  _echo_mock_state || return 1
  sed -n "${2}p" "${ECHO_MOCK_DIR}/${1}.log" 2>/dev/null | cut -f1
}

mock_get_call_user() { whoami 2>/dev/null || echo "${USERNAME:-${USER:-unknown}}"; }
mock_get_call_env() {
  if [ "$#" -ne 1 ]; then flunk "mock_get_call_env requires a variable name."; return 1; fi
  printenv "${1}" 2>/dev/null || echo ""
}

##
# Verify the mock bin directory is on PATH.
##
mock_path_check() {
  _echo_mock_state || return 1
  case ":${PATH}:" in
    *":${ECHO_MOCK_BIN}:"*) return 0 ;;
  esac
  format_error "Mock bin directory is not on PATH" "dir" "${ECHO_MOCK_BIN}" | flunk
  return 1
}

##
# Assert the exact recorded call sequence (args per call).
#
# Arguments:
#   1. name: Mock name.
#   2+. expected args, one per call, in order.
##
mock_assert_calls() {
  if [ "$#" -lt 1 ]; then flunk "mock_assert_calls requires a name."; return 1; fi
  _echo_mock_state || return 1
  local name="${1}"
  shift
  local actual
  actual="$(cut -f1 "${ECHO_MOCK_DIR}/${name}.log" 2>/dev/null)"
  local expected
  expected="$(printf '%s\n' "$@")"

  if [ "${actual}" != "${expected}" ]; then
    format_error "Call sequence differs" "mock" "${name}" "expected" "${expected}" "actual" "${actual}" | flunk
    return 1
  fi
}

mock_assert_no_calls() {
  if [ "$#" -ne 1 ]; then flunk "mock_assert_no_calls requires a name."; return 1; fi
  if [ "$(mock_get_call_num "${1}")" != "0" ]; then
    format_error "Mock was unexpectedly called" "mock" "${1}" | flunk
    return 1
  fi
}

mock_assert_called() {
  if [ "$#" -ne 1 ]; then flunk "mock_assert_called requires a name."; return 1; fi
  if [ "$(mock_get_call_num "${1}")" = "0" ]; then
    format_error "Mock was never called" "mock" "${1}" | flunk
    return 1
  fi
}

mock_assert_not_called() { mock_assert_no_calls "$@"; }

##
# Assert the Nth call received exact args.
##
mock_assert_call_args() {
  if [ "$#" -ne 3 ]; then flunk "mock_assert_call_args requires a name, a call number and args."; return 1; fi
  local actual
  actual="$(mock_get_call_args "${1}" "${2}")" || return 1

  if [ "${actual}" != "${3}" ]; then
    format_error "Call args differ" "mock" "${1}" "call" "${2}" "expected" "${3}" "actual" "${actual}" | flunk
    return 1
  fi
}

##
# Verify every spec ran its expected count.
#
# Arguments:
#   1. name: Mock name. Empty verifies all mocks.
##
mock_verify() {
  _echo_mock_state || return 1
  local failed=0
  local spec
  local name="${1-}"

  for spec in "${ECHO_MOCK_DIR}/${name:+${name}.}spec."*.args; do
    [ -e "${spec}" ] || continue
    local base="${spec%.args}"
    local used
    used="$(cat "${base}.used" 2>/dev/null || echo 0)"
    local count
    count="$(cat "${base}.count" 2>/dev/null || echo 1)"

    if [ "${used}" != "${count}" ]; then
      format_error "Spec ran an unexpected number of times" "spec" "$(cat "${base}.args")" "expected" "${count}" "actual" "${used}" | flunk
      failed=1
    fi
  done

  return "${failed}"
}

##
# Strict mode: unanswered calls fail the test instead of succeeding empty.
#
# Arguments:
#   1. on/off: Enable or disable. Default on.
##
mock_set_strict() {
  _echo_mock_state || return 1
  local mode="${1-on}"

  if [ "${mode}" = "on" ]; then
    : > "${ECHO_MOCK_DIR}/strict"
  else
    rm -f "${ECHO_MOCK_DIR}/strict"
  fi
}

##
# Sandbox: only mocks and allow-listed commands resolve; everything else is
# denied loudly by name.
#
# The sandbox rebuilds PATH as farm + mock bin, where the farm holds the
# allow-listed commands (symlinked, copied when the platform cannot link).
# Arguments:
#   1+. allowed: Commands that still run for real.
##
mock_sandbox_enable() {
  _echo_mock_state || return 1
  printf '%s\n' "${PATH}" > "${ECHO_MOCK_DIR}/sandbox-path"
  local farm="${ECHO_MOCK_DIR}/sandbox-bin"
  mkdir -p "${farm}"
  local allowed="bash ${*}"
  local name
  local target

  for name in ${allowed}; do
    target="$(command -v "${name}" 2>/dev/null)" || continue
    [ -n "${target}" ] && [ -f "${target}" ] || continue
    ln -s "${target}" "${farm}/${name}" 2>/dev/null || cp -f "${target}" "${farm}/${name}" 2>/dev/null || true
  done

  printf '%s\n' "$@" > "${ECHO_MOCK_DIR}/sandbox-allow"
  PATH="${farm}:${ECHO_MOCK_BIN}"

  command_not_found_handle() {
    echo "sandbox: denied '${1}'" >&2
    return 127
  }
}

mock_sandbox_allow() {
  _echo_mock_state || return 1
  local farm="${ECHO_MOCK_DIR}/sandbox-bin"
  local name
  local target

  for name in "$@"; do
    target="$(command -v "${name}" 2>/dev/null)" || continue
    # Resolve against the saved PATH when sandboxed: 'command -v' above sees
    # the farm first, so re-resolve from the original PATH instead.
    target="$(PATH="$(cat "${ECHO_MOCK_DIR}/sandbox-path" 2>/dev/null)" command -v "${name}" 2>/dev/null)" || continue
    [ -n "${target}" ] && [ -f "${target}" ] || continue
    ln -s "${target}" "${farm}/${name}" 2>/dev/null || cp -f "${target}" "${farm}/${name}" 2>/dev/null || true
    printf '%s\n' "${name}" >> "${ECHO_MOCK_DIR}/sandbox-allow"
  done
}

mock_sandbox_disable() {
  unset -f command_not_found_handle 2>/dev/null || true

  if [ -f "${ECHO_MOCK_DIR:-/nonexistent}/sandbox-path" ]; then
    IFS= read -r PATH < "${ECHO_MOCK_DIR}/sandbox-path" || [ -n "${PATH}" ]
    export PATH
    command -p rm -f "${ECHO_MOCK_DIR}/sandbox-path"
  fi

  command -p rm -rf "${ECHO_MOCK_DIR:-/nonexistent}/sandbox-bin" 2>/dev/null || true
}

mock_sandbox_enabled() {
  [ -f "${ECHO_MOCK_DIR:-/nonexistent}/sandbox-path" ]
}

mock_sandbox_report() {
  if mock_sandbox_enabled; then
    echo "sandbox enabled; allowed:"
    cat "${ECHO_MOCK_DIR}/sandbox-allow" 2>/dev/null
  else
    echo "sandbox disabled"
  fi
}

##
# Print the call log, optionally filtered.
##
mock_log_print() {
  _echo_mock_state || return 1
  local name="${1-}"

  if [ -n "${name}" ]; then
    cat "${ECHO_MOCK_DIR}/${name}.log" 2>/dev/null || true
  else
    local log
    for log in "${ECHO_MOCK_DIR}"/*.log; do
      [ -e "${log}" ] || continue
      echo "== $(basename "${log}" .log) =="
      cat -- "${log}"
    done
  fi
}

mock_log_exclude() {
  printf '%s\n' "$@" >> "${ECHO_MOCK_DIR}/log-exclude" 2>/dev/null || true
}
