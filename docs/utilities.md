# Utilities

## cleanup

```bash
cleanup_register "rm -rf '${dir}'"   # one string, quote paths yourself
cleanup_run                          # LIFO; failures reported, rest still runs
```

Pass a single string (redirects work); call `cleanup_run` from `teardown`, directly.

## retry

```bash
retry_run 5 0.5 curl -fsS https://example.com/health
```

Bounds: attempts + delay, optional `ECHO_RETRY_TIMEOUT` deadline. Report vars `ECHO_RETRY_ATTEMPTS/OUTPUT/ELAPSED` — read them after a **direct** call; `run` cannot carry variables back to your shell.

## fixture

```bash
dir="$(fixture_prepare_dir case1)"
printf 'hello\n' > "${dir}/a.txt"
archive="$(fixture_dump_dir "${dir}")"
fixture_assert_dir "${dir}" "${archive}"   # per-file unified diffs
```

Archive format: `@@ relative/path` lines followed by verbatim content. Text files only.

## dataprovider

```bash
double() { printf '%s' "$(( ${1} * 2 ))"; }
check() { [ "${2}" = "8" ]; }
dataprovider_run double check "$(dataprovider_case four 4)"
dataprovider_matrix COLOR "red blue" SIZE "s m"   # cartesian lines
```

## steps

```bash
steps_run "migrate" "drush updb -y" "clear" "drush cr"  # stops loudly at first failure
```

## tui

```bash
tui_run ./ask-name.sh "Ada"          # answers to STDIN, transcript kept
tui_assert_prompts "Your name"       # in-order substring assertions
```

`ECHO_TUI_OUTPUT/STATUS` hold the transcript and exit code. `ECHO_TUI_TIMEOUT` bounds hung scripts where `timeout` exists.
