load "../load.bash"

setup() {
  mock_setup
}

@test "mock records calls with responses in order" {
  mock_create greet
  mock_set_output greet "hello"
  run greet Ada
  assert_success
  assert_output "hello"
  run greet Bo
  assert_success
  assert_equal "$(mock_get_call_num greet)" "2"
  assert_equal "$(mock_get_call_args greet 1)" "Ada"
  assert_equal "$(mock_get_call_args greet 2)" "Bo"
  mock_assert_calls greet "Ada" "Bo"
  mock_assert_called greet
}

@test "mock per-call status and output" {
  mock_create flaky
  mock_set_status flaky 1 3
  mock_set_output flaky 1 "first"
  run flaky
  assert_status 3
  assert_output "first"
  run flaky
  assert_success
  mock_assert_call_args flaky 2 ""
}

@test "mock specs match args and verify counts" {
  mock_create deploy
  mock_spec_add deploy --env prod
  mock_spec_set_output deploy "live"
  mock_spec_count deploy 2
  run deploy --env prod
  assert_output "live"
  run deploy --env prod
  assert_output "live"
  mock_verify deploy
}

@test "mock strict fails unanswered calls" {
  mock_create picky
  mock_set_strict
  run picky
  assert_failure
  assert_output_contains "strict mode"
  mock_set_strict off
}

@test "mock sandbox denies unknown commands" {
  mock_sandbox_enable printf
  run unknown-echo-command-xyz
  assert_equal "${status}" "127"
  assert_output_contains "sandbox: denied"
  mock_sandbox_disable
  run printf 'back'
  assert_success
}

@test "mock side effects run" {
  mock_create worker
  mock_set_side_effect worker 1 "touch \"${BATS_TEST_TMPDIR}/side-effect\""
  run worker
  assert_success
  assert_file_exists "${BATS_TEST_TMPDIR}/side-effect"
}
