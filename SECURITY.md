# Security Policy

## Supported versions

Security fixes are released for the latest `1.x` only.

| Version | Supported |
| --- | --- |
| 1.x | Yes |

## Reporting a vulnerability

Report vulnerabilities privately — never via public issue. Use [GitHub Security Advisories](https://github.com/JovianOps/echo/security/advisories/new).

## Scope

In scope: mock sandbox escapes (a denied command executing anyway), cleanup running unregistered commands.

A test library runs with your privileges by design — that is not a vulnerability. Findings in consuming projects' own tests are out of scope.
