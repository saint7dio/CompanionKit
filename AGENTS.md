# AGENTS.md

## Product

CompanionKit is a native macOS 14+ SwiftUI/AppKit desktop pet that exposes
deterministic everyday actions. It is local-first, permission-minimizing,
accessible, and intentionally has no MVP account, analytics, advertising,
backend, API key, or AI dependency.

Veya is the canonical default companion: an original, wingless Ethereal
soul-orb with no fixed animal anatomy. The personal display name is configurable.
Never introduce wings, animal ears/paws/whiskers, copied mascot features, or a
winged Veya as the default. Never convert the app to Electron.

## Boundaries

- Keep domain models, protocols, services, and errors in `CompanionKit/Core`.
- Keep user-facing capabilities grouped under `CompanionKit/Features`.
- Isolate AppKit and operating-system adapters under `CompanionKit/Platform`.
- UI may call view models or action policy, not uncontrolled platform globals.
- Register actions through the action abstraction/registry and inject services
  so policy and failures remain testable.

## Commands

Run from the repository root:

```sh
swift build
swift test
swift run CompanionKit
```

The authoritative native project is `CompanionKit.xcodeproj` with the shared
`CompanionKit` scheme; exact `xcodebuild` commands are in
`docs/DEVELOPMENT.md`. No lint or format tool is currently configured; do not
claim or require one until its config and CI step exist.

## Change rules

- Support macOS 14+ and use public APIs.
- Keep semantic companion state separate from visual animation values. Motion
  must be cancellable, restrained, suspended while hidden, and must respect
  system Reduce Motion; personality must never alter safety or permissions.
- Prefer small, focused types; no force unwraps in production, swallowed errors,
  giant views/managers, hidden global state, or unstructured user-facing errors.
- Never add arbitrary shell commands, user-authored AppleScript, downloaded
  execution, unsafe dynamic loading, credential collection, keylogging,
  clipboard history, hidden capture/automation, network listeners, telemetry,
  advertising, or secrets.
- Permission requests must be contextual, explained, and safely deniable. Never
  simulate success or force Accessibility access.
- Never bypass or disguise a macOS permission prompt.
- Do not add dependencies without a concrete need, license review, and security
  rationale.
- Preserve useful keyboard and menu-bar alternatives. Add VoiceOver labels,
  visible focus, non-color-only feedback, sufficient contrast, and Reduce
  Motion handling for relevant UI.
- Use original/repository-owned visuals or SF Symbols; do not introduce copied
  characters, mascots, fonts, or unlicensed assets.

## Tests and documentation

Add focused tests for changed policy and logic, especially action availability,
confirmation, typed errors, settings, timers, permissions, and position
clamping. Run `swift build` and `swift test`; report any skipped validation.

Update documentation in the same change whenever behavior, permissions,
entitlements, stored data, dependencies, architecture, accessibility, build
steps, or release status changes. Mark future work as unimplemented and never
claim benchmarks, signing, notarization, distribution, or accessibility testing
that was not performed.

## Definition of done

A change is done when it builds without new warnings, relevant tests pass,
failure/denial paths are understandable, accessibility/privacy/security impacts
are reviewed, docs match behavior, and no generated artifacts or secrets are
included.
