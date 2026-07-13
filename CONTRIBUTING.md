# Contributing to CompanionKit

Thank you for helping build a calm, useful, and trustworthy Mac companion.
CompanionKit welcomes code, tests, documentation, accessibility feedback, and
original visual contributions.

## Before you start

- Search existing issues and pull requests before opening a duplicate.
- Use an issue for behavior changes or substantial design work so scope can be
  discussed first.
- Report suspected vulnerabilities privately as described in
  [SECURITY.md](SECURITY.md), not in a public issue.
- Ensure art, sound, and other assets are original or have a compatible license
  documented in the contribution.

## Development setup

Current prerequisites:

- macOS 14 or later;
- Xcode 16 or later with the macOS 14 SDK or later;
- Swift 6 toolchain support;
- Git.

Clone the repository, then run:

```sh
swift build
swift test
```

The package currently uses Swift language mode 5 for compatibility while being
built by a Swift 6 toolchain. The native app project is
`CompanionKit.xcodeproj`, and its shared scheme is `CompanionKit`. Follow
`docs/DEVELOPMENT.md` for the authoritative Xcode and secondary SwiftPM
commands.

No linter or formatter is currently configured. Use Xcode's standard Swift
formatting and match adjacent code. Do not make a contribution depend on an
unconfigured global tool.

## Branches and commits

Use a short, descriptive branch such as `feature/timer-presets`,
`fix/window-clamping`, or `docs/privacy-clarification`. Automation-created
branches may use the repository's configured prefix.

Keep commits focused. Write imperative subjects that explain the outcome, for
example `Add denied-notification fallback`. Avoid combining broad refactors
with behavior changes unless they cannot reasonably be separated.

The project does not currently require a Developer Certificate of Origin or a
Contributor License Agreement.

## Engineering expectations

- Use public macOS APIs and preserve the macOS 14 minimum deployment target.
- Keep UI, domain policy, persistence, and AppKit adapters separated.
- Add deterministic actions through the action abstraction and registry; do not
  add arbitrary shell, user-authored AppleScript, or dynamic code execution.
- Request permissions only in context and keep useful behavior available when
  a permission is denied.
- Do not add analytics, advertising, account requirements, credential
  collection, hidden automation, network listeners, or mandatory cloud calls.
- Avoid unnecessary dependencies. Explain any proposed dependency's ownership,
  license, update policy, and security impact.
- Never commit secrets, personal data, provisioning profiles, or signing keys.

## Tests

Every behavior change should include appropriate tests. Prioritize stable tests
of action policy, typed errors, settings, timer transitions, position clamping,
and permission-denied behavior. Run at minimum:

```sh
swift build
swift test
```

Document any test you could not run and why. UI changes should also be checked
manually in light and dark appearances, with keyboard navigation, VoiceOver,
and Reduce Motion as relevant.

## Accessibility, privacy, and security

Accessibility is part of acceptance, not optional polish. Interactive controls
need descriptive labels, keyboard access, visible focus, non-color-only status,
and layouts that tolerate larger text. Motion must respect system preferences.

Update [PRIVACY.md](PRIVACY.md), `docs/PERMISSIONS.md`, and the threat model when
a change affects stored data, permissions, entitlements, process boundaries,
or network behavior. A pull request must call out "none" explicitly when there
is no privacy, security, or accessibility impact.

## Pull requests

1. Rebase or merge the current default branch as appropriate.
2. Keep the pull request scoped and complete the template.
3. Add or update tests and documentation.
4. Include screenshots or a short recording for visible changes, taking care to
   remove personal information.
5. Confirm build and tests pass locally.
6. Respond to review feedback and avoid force-pushing while review is active
   unless necessary.

A maintainer may request changes for correctness, maintainability, product fit,
accessibility, privacy, security, or licensing reasons. By participating, you
agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
