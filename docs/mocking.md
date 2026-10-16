# Mocking

```bash
setup() { mock_setup; }

@test "deploys" {
  mock_create drush
  mock_set_output drush "done"
  run drush status
  assert_success
  mock_assert_calls drush "status"
}
```

## Responses

- `mock_set_output NAME [N] TEXT` / `mock_set_status NAME [N] CODE` — default for all calls, or call N (1-based).
- `mock_set_side_effect NAME N CODE...` — shell snippet run on call N.
- `mock_forward NAME REAL` — unanswered calls exec the real command.
- Unanswered calls succeed empty — unless `mock_set_strict` (no args), which fails them loudly.

## Specs (arg-matched responses)

```bash
mock_spec_add deploy --env prod
mock_spec_set_output deploy "live"
mock_spec_count deploy 2
# ... two calls ...
mock_verify deploy   # fails when a spec ran other than its count
```

Setters after `mock_spec_add` target the newest spec. `mock_verify [NAME]` checks every spec ran exactly its count.

## Call log

`mock_get_call_num`, `mock_get_call_args NAME N`, `mock_assert_calls NAME "args1" "args2"`, `mock_assert_call_args`, `mock_assert_called`, `mock_assert_no_calls`, `mock_log_print`.

## Sandbox

```bash
mock_sandbox_enable grep sed   # only mocks + these resolve; rest denied by name
mock_sandbox_disable           # call directly, never via run
```

State lives in files (call counts, logs, responses) so it survives BATS `run` subshells. Anything that must affect your shell (disabling the sandbox) must be called directly — `run` cannot propagate shell state back.
