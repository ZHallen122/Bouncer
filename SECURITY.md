# Security Policy

## Reporting a Vulnerability

Please report security issues privately by emailing the maintainer listed on the GitHub profile, or by opening a private GitHub security advisory if the repository has advisories enabled.

Do not open a public issue for vulnerabilities that could expose users to risk.

## Scope

Bouncer is a local macOS menu bar utility. Security-sensitive areas include:

- process sampling and helper-process attribution
- notification actions that quit or restart apps
- SQLite history and baseline storage
- Sparkle update configuration, appcast signing, and release signing

## Supported Versions

Security fixes are expected to target the latest released version.
