load "../load.bash"

@test "cleanup runs last-registered-first" {
  cleanup_register "printf 'first\n' >> '${BATS_TEST_TMPDIR}/order'"
  cleanup_register "printf 'second\n' >> '${BATS_TEST_TMPDIR}/order'"
  cleanup_run
  run cat "${BATS_TEST_TMPDIR}/order"
  assert_line 0 "second"
  assert_line 1 "first"
}

@test "retry succeeds and counts attempts" {
  retry_run 3 0 printf 'eventually'
  assert_equal "${ECHO_RETRY_ATTEMPTS}" "1"
}

@test "retry exhausts attempts" {
  retry_run 2 0 false 2>/dev/null || status="$?"
  assert_equal "${status}" "1"
  assert_equal "${ECHO_RETRY_ATTEMPTS}" "2"
}

@test "file utils roundtrip" {
  local target="${BATS_TEST_TMPDIR}/sub/dir/file.txt"
  file_mktouch "${target}"
  assert_file_exists "${target}"
  printf 'KEY=value\n# comment\n\nEMPTY=\n' > "${target}"
  file_read_env "${target}"
  assert_equal "${KEY}" "value"
  file_add_var "${target}" "EXTRA=1"
  assert_file_contains "${target}" "EXTRA=1"
  file_restore "${target}"
  assert_file_not_contains "${target}" "EXTRA=1"
}

@test "fixture dump and assert roundtrip" {
  local dir
  dir="$(fixture_prepare_dir case1)"
  printf 'hello\n' > "${dir}/a.txt"
  mkdir -p "${dir}/sub"
  printf 'world\n' > "${dir}/sub/b.txt"
  local archive
  archive="$(fixture_dump_dir "${dir}")"
  fixture_assert_dir "${dir}" "${archive}"
  printf 'changed\n' > "${dir}/a.txt"
  run fixture_assert_dir "${dir}" "${archive}"
  assert_failure
}

@test "dataprovider cases and matrix" {
  double() { printf '%s' "$(( ${1} * 2 ))"; }
  check_double() { [ "${2}" = "8" ] && [ "${1}" = "four" ]; }
  run dataprovider_run double check_double "$(dataprovider_case four 4)"
  assert_success
  run dataprovider_matrix COLOR "red blue" SIZE "s m"
  assert_success
  assert_line_count 4
}

@test "steps run in order and stop" {
  steps_run "one" "printf '1' >> '${BATS_TEST_TMPDIR}/steps'" "two" "printf '2' >> '${BATS_TEST_TMPDIR}/steps'"
  run cat "${BATS_TEST_TMPDIR}/steps"
  assert_output "12"
  run steps_run "ok" "true" "bad" "false"
  assert_failure
  assert_output_contains "Step failed"
}

@test "tui answers and asserts prompts" {
  local script="${BATS_TEST_TMPDIR}/ask.sh"
  printf '#!/usr/bin/env bash\nread -r name\necho "Hello, ${name}."\n' > "${script}"
  chmod +x "${script}"
  tui_run "${script}" "Ada"
  assert_equal "${ECHO_TUI_STATUS}" "0"
  assert_string_contains "${ECHO_TUI_OUTPUT}" "Hello, Ada."
}
