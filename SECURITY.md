# Security Policy

CompanionKit treats desktop automation and macOS permissions as
security-sensitive, even when an action appears simple.

## Supported versions

CompanionKit is in pre-release development. Until the first tagged release,
security fixes are made on the default branch only. After releases begin, this
section will list the versions receiving security updates.

| Version | Supported |
| --- | --- |
| Default branch (pre-release) | Yes |
| Tagged releases | None published yet |

## Reporting a vulnerability

Do **not** open a public issue for a suspected vulnerability or include exploit
details in a public discussion.

Preferred reporting path:

1. Use GitHub's private vulnerability reporting feature for this repository, if
   it is enabled.
2. Otherwise, use the private maintainer contact method shown in the repository
   owner profile or project website.

**Maintainer publication blocker:** enable GitHub private vulnerability
reporting or replace this paragraph with a real monitored private contact. No
security email address is invented in this repository.

Include, when safe:

- affected revision or version;
- macOS and hardware context;
- impact and expected security boundary;
- reproducible steps or a minimal proof of concept;
- whether special permissions are required;
- any proposed mitigation;
- a way to contact you privately.

Do not send credentials, unrelated personal data, or full screenshots that
contain private information.

## What to expect

Maintainers aim to acknowledge a report within 5 business days and provide an
initial assessment within 10 business days. These are response targets, not a
guarantee. The reporter will be updated when material status changes.

If a report is accepted, maintainers will coordinate a fix and disclosure date,
credit the reporter if requested, and publish remediation guidance appropriate
to the project's release status. Please allow a reasonable remediation period
before public disclosure.

## Security boundaries

Contributions must preserve these baseline rules:

- only allowlisted, deterministic actions;
- no arbitrary shell or user-provided AppleScript execution;
- no download-and-execute behavior or unsafe dynamic code loading;
- no credential collection, keylogging, clipboard history, or hidden capture;
- no network listener, local HTTP server, analytics, or advertising;
- permissions requested only when needed and denial handled transparently;
- no secrets, signing credentials, or personal provisioning data in source;
- explicit, visible confirmation for actions whose risk warrants it.

See `docs/THREAT_MODEL.md` for the detailed model when that document is present.
