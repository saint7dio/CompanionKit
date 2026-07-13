# CompanionKit Roadmap

This roadmap describes direction, not a delivery promise. A checkbox is marked
complete only after implementation and relevant validation exist in the
repository. Source stubs and protocols alone do not count as delivered.

## MVP: trustworthy native companion

### Foundation

- [x] Produce a runnable native macOS 14+ application project with a shared
  scheme and documented local build path.
- [x] Keep UI, domain policy, persistence, and macOS adapters modular and
  testable.
- [x] Establish CI that builds and tests the authoritative project without
  secrets.

### Veya desktop companion

- [x] Display original wingless Veya with a procedural Ethereal renderer in a
  transparent, non-aggressive floating window.
- [x] Support dragging, multi-display visible-frame clamping, saved position,
  show/hide, and position reset.
- [x] Provide ten semantic companion states, personality-scaled motion, and
  effective Reduce Motion behavior.
- [x] Provide a keyboard/menu-bar alternative to precise pointer interaction.

### Deterministic actions

- [x] Register fourteen reliable actions implemented through public APIs.
- [x] Show action name, icon, description, availability, risk/confirmation
  policy, progress, and truthful result.
- [x] Handle missing capabilities, invalid configuration, cancellation, and
  permission denial with understandable typed errors.
- [x] Prohibit arbitrary shell/script execution and dynamic downloaded actions.

The exact initial action set should be selected by reliability. Candidates are
opening Finder, Downloads, System Settings, or a selected application; showing
the system screenshot interface; volume changes where supported; hiding other
applications; copying a configured snippet; showing date/time; and local timer
controls.

### Timer, customization, and onboarding

- [x] Implement a local timer with start, remaining-time display, cancellation,
  optional local notification, and safe restoration where practical.
- [x] Persist settings for Veya’s personal name, size, Ethereal color, aura,
  particles, personality, appearance, motion, visibility, and shortcuts.
- [x] Add concise onboarding and request permissions only when a relevant
  feature is invoked.
- [x] Add menu-bar controls for Veya visibility, actions, timer, personality,
  settings, animation,
  position reset, About, and Quit.

### Accessibility and quality

- [ ] Verify VoiceOver labels, keyboard navigation, visible focus, meaningful
  control names, non-color-only feedback, contrast, larger-text tolerance, and
  Reduce Motion behavior.
- [x] Keep denied permissions non-blocking for unrelated features.
- [x] Cover action policy, settings, companion/theme/personality state, timer
  state, error mapping, confirmation,
  and position clamping with meaningful automated tests.
- [ ] Review idle work, cancellation, timer lifetime, memory ownership, and
  unnecessary disk writes; publish no performance numbers without measurement.
- [x] Ensure privacy, permission, accessibility, threat-model, development, and
  release documentation matches the code.

## Next

Everything below is **unimplemented future work** unless moved into a completed
release entry in [the changelog](../CHANGELOG.md):

- Pixel Wisp and additional original themes (Forest Spirit, Cosmic, Mono,
  Mechanical, Warm Ember, Frost, and Void);
- restrained optional original sound design;
- localization;
- signed releases and Homebrew Cask;
- richer reviewed action packs and a constrained companion SDK.

## Later

- community theme packs and reviewed plugin ecosystem;
- optional natural-language input constrained to registered actions;
- optional local-model integration;
- opt-in cloud AI with updated privacy terms and explicit consent;
- broader automated UI and accessibility regression coverage.

The following older directions remain future-only:

- additional original pets and community themes;
- richer, still-efficient animations;
- user-created action packs with a constrained manifest/schema;
- a documented plugin SDK with allowlisting, capability boundaries, and review;
- optional natural-language intent parsing that can only propose registered
  actions;
- optional on-device/local models;
- optional cloud AI integrations with explicit consent and updated privacy
  terms;
- signed and notarized releases.

Natural-language or plugin work must not bypass deterministic authorization and
execution policy. Models must never execute arbitrary scripts or shell commands.

## Explicit MVP non-goals

- accounts, authentication, advertising, analytics, or a CompanionKit backend;
- autonomous background computer control;
- arbitrary user-authored automation;
- private macOS APIs;
- an App Store or Homebrew release before signing, privacy, and operational
  requirements have been verified.

## Status review checklist

Before marking an MVP item complete, link or identify:

1. the implementation;
2. automated tests where practical;
3. manual validation for UI, permissions, or accessibility behavior;
4. any documentation affected;
5. limitations that remain.
