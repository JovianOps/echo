# Contributing to Echo

> **Vibecoders welcome.** `AGENTS.md` gets your agent running in minutes. BATS runs on Windows Git Bash, so no excuses.

## Quickstart

```bash
npm install
./node_modules/.bin/bats tests   # must stay green on your machine
```

## Rules

Short version: see `AGENTS.md`. Original work only, portable-first (Alpine + Windows are first-class, not afterthoughts), file-based state across `run`, a test for every assertion, docs in sync.

## Pull request workflow

1. Fork and branch from `main`.
2. `bats tests` green locally.
3. Describe the assertion semantics (verb, negation, case) and the portability risks you checked.

## Mandatory compliance & eligibility notice

By cloning, forking, opening a pull request, submitting an issue, or otherwise interacting with this repository, **you explicitly certify and warrant that you are not an Excluded Party** as defined in Section 3 of the [LICENSE](./LICENSE) (specifically including **DrevOps**, its corporate affiliates, or **Alex Skrypnyk**). Any contribution submitted by an excluded entity or individual is legally void and prohibited.
