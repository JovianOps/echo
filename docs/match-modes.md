# Match modes

How a needle is read, and whether case matters, is chosen by the assertion name — there are no flags.

Three things vary. **How the needle is read** is the verb:

| Verb | The needle is |
| :--- | :--- |
| `contains` | A literal substring |
| `starts_with` | A literal prefix |
| `ends_with` | A literal suffix |
| `matches` | An extended regular expression (`grep -E`) |
| `matches_format` | A format string (see below) |

**Presence** is the `not_` prefix; **case** is the `_case` suffix. Without the suffix, matching ignores case:

```bash
assert_output_contains "Deleted 12 files"    # matches "deleted 12 FILES"
assert_output_contains_case "Deleted"        # strict case
assert_output_not_contains "Removed"
assert_output_matches 'Deleted [0-9]+ files'
assert_output_matches_format "Deleted %d files"
```

## Format strings

Prefer literals. Reach for `matches` only for the part that genuinely varies; where the variation is a number or a word, `matches_format` says so:

| Placeholder | Matches |
| :--- | :--- |
| `%d` | Digits (`[0-9]+`) |
| `%f` | Number, optional fraction |
| `%s` | Non-whitespace run (`[^[:space:]]+`) |
| `%%` | Literal `%` |

Everything else is literal:

```bash
assert_output_matches_format "Deleted %d files in %fs"
```

## Scope

Verbs apply to the whole value (`output`, `stderr`, file content, one `lines` entry) — `^`/`$` anchor the whole value, not each line.
