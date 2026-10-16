# AGENTS.md — vibecoding on `jovian/echo`

Portable BATS helpers. Same API family as the genre, original bodies, Windows + Alpine green from day one.

## Run everything (Windows Git Bash here)

```powershell
& 'C:\Program Files\Git\bin\bash.exe' C:\Users\RDC\AppData\Local\Temp\opencode\run_echo.sh
```

That runs `bats tests/`. In CI: ubuntu, macos, windows, alpine legs.

## Rules

1. **Original work only.** API names mirror the genre for drop-in familiarity; every body is ours.
2. Portable-first: no GNU-only flags, no macOS-only tools, no `timeout` dependency, BSD fallbacks where platforms differ.
3. **State crosses `run` in files, never variables.** BATS `run` executes in a subshell: counters, logs and registries must live under `$BATS_TEST_TMPDIR`/state dirs. Direct calls (not via `run`) see variables fine. State-changing helpers (`mock_sandbox_disable`, `cleanup_run`) must be callable directly — never require `run`.
4. `read` without trailing newline returns 1 despite assigning — guard every `read < file` with `|| [ -n ... ]`.
5. Every new assertion gets a green test on this machine AND must survive all four CI legs. BusyBox (Alpine) and Git Bash (Windows) are the strict teachers.
6. Docs per module under `docs/` stay in sync with the code.
