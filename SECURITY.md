# Security policy

## Reporting a vulnerability

**Please don't open a public issue for security problems.**

Report them privately through GitHub: go to the repository's **Security** tab and choose
**Report a vulnerability**. Only the maintainers see the report.

Please include:
- what an attacker could do, and under which conditions
- steps or a proof of concept to reproduce it
- the Fennek OS image version (`rpm-ostree status`)

You'll get an answer within 7 days. Once a fix is published, we credit you in the release notes, unless you
prefer to stay anonymous.

## What's in scope

Everything Fennek OS adds on top of its base, including:
- the Windows-program sandbox (`fennek-run-exe`)
- the firewall (`fennek-firewall` and the default zones)
- the download guard, file search, VirusTotal check and snapshots
- the build itself (supply chain, signatures, file ownership)

Vulnerabilities in the base (the Linux kernel, KDE, Fedora packages) belong to those projects. Report them
there. Fennek picks up their fixes automatically through the daily rebuild.

## Supported versions

Only the latest published image (`ghcr.io/olexify/fennekos:latest`) gets security fixes. Installed systems
update to it automatically.
