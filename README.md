# Echo 🦇

Portable BATS helpers and assertions. One `load`, fourteen modules, zero platform excuses — Ubuntu, macOS, Windows (Git Bash) and Alpine (busybox) run the same suite green.

```bash
load "path/to/echo/load.bash"

@test "deploy works" {
  mock_setup
  mock_create drush
  mock_set_output drush "done"
  run drush status
  assert_success
  assert_output_contains "done"
  mock_assert_calls drush "status"
}
```

## Modules

| File | Provides |
| :--- | :--- |
| `assert.base` | `flunk`, `format_error`, banners, diffs, stack traces |
| `assert.string` | empty/equal, contains/starts/ends, regex, `%d/%f/%s` formats — each plain, `_case`, `not_`, `not_.._case` |
| `assert.command` | status family + the twelve match forms on `output` and `stderr` |
| `assert.line` | indexed, any/no-line, and counted assertions on `lines` |
| `assert.file` | presence, mode, content, directory and tree equality |
| `assert.git` | repo, tracked, clean assertions |
| `cleanup` | LIFO deferred commands via `cleanup_register`/`cleanup_run` |
| `retry` | `retry_run` with attempt/deadline bounds and `ECHO_RETRY_*` report vars |
| `file` | mktouch, trim, dotenv read, backup/restore vars |
| `fixture` | sandbox dirs + plain-text directory archives with diffs |
| `dataprovider` | named cases, matrix expansion |
| `mock` | shims with per-call responses, arg-matched specs, strict mode, a real PATH sandbox, call-log assertions |
| `steps` | ordered snippets that stop loudly |
| `tui` | scripted answers with transcript assertions |

Case-insensitive is the default everywhere (history); append `_case` for strict case. Failure reports show aligned rows, unified diffs for multiline values, and stack traces pointing at your code — with volatile paths rewritten to variable names.

## Portability contract

- Bash 4.4+ constructs only; external tools limited to POSIX + `grep -E`, `diff -u`, `find`, `mktemp`.
- File modes via GNU `stat -c` with BSD `stat -f` fallback.
- No GNU-only `sed -i`, no `/dev/shm`, no `timeout` requirement (deadlines degrade to plain runs where `timeout` is absent, e.g. macOS).
- State that must cross BATS `run` boundaries lives in files, never in variables (documented in AGENTS.md).

## Verification status (honest)

- ✅ `bats tests` — 16 tests green on Windows Git Bash here; ubuntu/macos/windows/alpine legs run in CI on every push.
- ✅ `shellcheck`-clean is aspirational, not yet enforced (see issues).
