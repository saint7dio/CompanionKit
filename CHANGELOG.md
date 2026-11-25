# Changelog

All notable changes to CompanionKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project intends to use [Semantic Versioning](https://semver.org/) once
public versioned releases begin.

## [Unreleased]

### Added

- Native SwiftUI/AppKit desktop companion with a transparent draggable panel,
  original wingless Veya soul-orb renderer and vector icon, persisted
  multi-display-aware position, ten semantic states, and Reduce Motion support.
- Fourteen allowlisted actions with injected services, live availability,
  confirmation policy, serialized execution, and structured feedback.
- Restorable local countdown timer with contextual notification permission,
  cancellation, and foreground notification presentation.
- Ethereal color/aura/particle customization, Calm/Friendly/Energetic
  personalities, four-page Veya onboarding, timer/personality menu controls,
  launch-at-login service, and migration-safe local `UserDefaults` persistence.
- Native `CompanionKit.xcodeproj`, shared app/test scheme, and a secondary Swift
  Package build path targeting macOS 14.
- Thirty-seven deterministic Swift Testing tests covering action policy, errors,
  Veya state/theme/personality, settings migration, timers, notification denial,
  and position clamping.
- GitHub Actions CI for SwiftPM and unsigned Xcode build/test checks, issue/PR
  templates, governance files, privacy/security documentation, architecture,
  accessibility guidance, threat model, and release roadmap.

### Fixed

- The countdown rejects unsupported durations and safely clears invalid
  saved deadlines instead of failing while formatting the remaining time.
- Reset All Settings now unregisters both enabled and pending-approval Login
  Item registrations.
- Favorite-app execution resolves symlinks and revalidates the target as an
  application bundle immediately before launch.

### Notes

- No public binary, signed archive, notarized build, or App Store release is
  represented by this changelog entry.

Comparison links will be added after the canonical repository URL and first
version tag exist.
