load "../src/assert.base.bash"
load "../src/assert.string.bash"
load "../src/assert.command.bash"
load "../src/assert.line.bash"

@test "string verbs" {
  run printf 'Hello World'
  assert_success
  assert_output "Hello World"
  assert_output_contains "hello"
  assert_output_contains_case "Hello"
  assert_output_not_contains "bye"
  assert_output_matches 'Hello [A-Z]+'
  assert_output_matches_format "Hello %s"
  assert_line 0 "Hello World"
  assert_line_count 1
  assert_any_line "Hello World"
  assert_no_line "bye"
}

@test "status verbs" {
  run false
  assert_failure
  assert_status 1
  assert_failure_status 1
  assert_status_general_error
  run bash -c 'exit 3'
  assert_status 3
}
