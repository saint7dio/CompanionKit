# CompanionKit Implementation Plan

Last reviewed against the source tree: 2026-07-13.

## V2 Soul-Orb specification execution

Binding source: `CompanionKit_Master_Prompt_v2_Soul_Orb.md`, supplied on
2026-07-13. The existing deterministic action, timer, settings, AppKit window,
test, and documentation work is valuable and will be evolved rather than
replaced.

### Assumptions

- The canonical included character is Veya; the persisted personal name remains
  user-editable.
- Veya is rendered procedurally with SwiftUI. The supplied visual model is a
  direction reference, not a redistributable runtime asset or a sprite-atlas
  requirement.
- Ethereal is the only implemented MVP theme. Pixel Wisp and other themes stay
  documented future work until the core build and validation gates pass.
- System Reduce Motion always wins. The in-app override may request less motion
  but may never force motion when macOS asks for reduction.
- Existing settings data must migrate safely when new Veya customization fields
  are introduced.

### Execution checklist

- [x] Re-inspect repository, Git status, Xcode, Swift, SDK, native project, and
  existing assets after receiving the V2 specification.
- [x] Preserve the working fourteen-action engine, timer, window controllers,
  privacy boundary, tests, and open-source foundation.
- [x] Replace the animal-like Pip renderer with original, wingless Veya and a
  layered Ethereal renderer (aura, tail, body/core, face, particles, overlay).
- [x] Add semantic idle, curious, thinking, working, success, error, sleeping,
  waiting, surprised, and hidden states with centralized transitions.
- [x] Add the Ethereal theme abstraction, customizable base color, aura and
  particle intensity, and Calm/Friendly/Energetic personality profiles.
- [x] Make settings migration-safe and cover the new defaults and persistence.
- [x] Connect action, hover, animation, timer, visibility, and temporary feedback
  events to the semantic state model without weakening action policy.
- [x] Update Settings, onboarding, menu bar, About, accessibility text, and
  original-character copy for Veya.
- [x] Add focused state, theme, personality, reduced-motion, and settings tests.
- [x] Add `docs/DESIGN_LANGUAGE.md` and `docs/COMPANION_STATES.md`; reconcile the
  README, architecture, accessibility, roadmap, privacy, threat model, and
  contributor/agent guidance.
- [x] Add the missing visual-theme and performance GitHub issue templates and
  required PR impact sections.
- [x] Run SwiftPM Debug/Release, SwiftPM tests, authoritative Xcode build/test,
  manual UI/accessibility-tree smoke tests, no-wing visual review, and repository
  consistency checks.

### Validation notes

- Baseline before V2 changes: Xcode 26.6, Swift 6.3.3, macOS SDK 26.5;
  SwiftPM Debug/Release and authoritative unsigned Xcode Debug builds passed;
  all 28 tests passed through SwiftPM and Xcode.
- V2 result: SwiftPM Debug/Release and the additional
  `-strict-concurrency=complete` build passed; all 36 tests passed through both
  SwiftPM and the authoritative unsigned Xcode Debug test path. The launched
  app's Veya window, action popover, Settings controls, accessibility tree, and
  no-wing visual identity were inspected locally.
- Manual VoiceOver operation, multiple-display behavior, real notification and
  permission-denial paths, signing, notarization, and distribution remain
  intentionally unclaimed.
- Git currently has no commits. All repository files are untracked, so ordinary
  `git diff` cannot represent the baseline until the owner authorizes an initial
  commit.

This is a status record as well as a work plan. A checked implementation item
means that source exists; it does not imply that the behavior has been manually
verified, signed, notarized, or released. Validation items are tracked
separately so repository claims remain auditable.

## Current baseline

- [x] Swift Package with a macOS 14 executable product named `CompanionKit`.
- [x] Native `CompanionKit.xcodeproj` application and unit-test targets with the
  repository-owned shared `CompanionKit` scheme.
- [x] SwiftUI application lifecycle with AppKit window, menu-bar, and platform
  adapters where native integration is required.
- [x] `Core`, `Features`, and `Platform/macOS` source boundaries.
- [x] No third-party package dependencies.
- [x] Generated Info.plist settings, current application bundle identifier
  `org.companionkit.CompanionKit`, version/build settings, original app icon asset
  catalog, and hardened-runtime build setting.
- [ ] Signing team/Developer ID configuration, App Sandbox decision,
  repository-owned entitlements file (if needed), and verified effective release
  signature/entitlements.

`CompanionKit.xcodeproj` is authoritative for the native `.app`, resources,
generated Info.plist, local running, testing, and future archives. `Package.swift`
is a supported secondary command-line build/test path. It uses Swift tools
version 6.0 and compiles its targets in Swift language mode 5, matching the
Xcode targets' Swift 5 mode.

## Phase status

### 1. Domain and platform foundation

- [x] Define action identity, category, capabilities, availability, risk,
  confirmation metadata, execution result, and typed user-facing errors.
- [x] Define injectable workspace, screenshot, audio, clipboard, notification,
  and launch-at-login service protocols.
- [x] Compose live services in `AppEnvironment` while allowing test doubles.
- [x] Keep the registered action list in `ActionRegistry` and reject duplicate
  identifiers.
- [x] Apply one `ActionConfirmationPolicy` in the action panel, menu bar, and
  executor. It requires confirmation for an explicit flag or `.high` risk, so
  direct executor calls cannot bypass the presentation check.

### 2. Desktop companion

- [x] Provide one original procedural pet made from SwiftUI shapes, gradients,
  and SF Symbols; there is no downloaded or third-party mascot art.
- [x] Use a transparent, borderless, nonactivating `NSPanel` at floating level.
- [x] Support dragging, show/hide, saved position, reset, and visible-frame
  clamping after display changes.
- [x] Represent idle, attentive, working, success, error, and sleeping states.
- [x] Respect system Reduce Motion for floating, working pulse, the short pet
  state transition, and action-popover animation. The app's animation and
  reduced-interaction settings also suppress repeating pet motion and popover
  animation.
- [ ] Manually exercise display removal, Spaces, full-screen applications,
  keyboard access, and VoiceOver on supported macOS versions.
- [ ] Abstract pet rendering before adding a second appearance; the current
  procedural appearance is intentionally implemented directly in `PetView`.

### 3. Deterministic actions

- [x] Register fourteen allowlisted actions: Open Finder; Open Downloads,
  Documents, Desktop, and Applications; Open Favorite App; Take a Screenshot;
  Volume Up; Volume Down; Mute or Unmute; Date and Time; Copy Saved Text; Hide
  Other Apps; and Open System Settings.
- [x] Check favorite-app configuration and audio capability before enabling
  affected actions.
- [x] Require explicit confirmation before Hide Other Apps.
- [x] Report structured success or mapped, user-facing failure; do not simulate
  success when a service throws.
- [x] Use public `NSWorkspace`, `NSApplication`, `NSPasteboard`, and Core Audio
  APIs. The screenshot action opens Apple's Screenshot app rather than capturing
  the screen itself.
- [ ] Verify every action on macOS 14 and a current macOS version, including
  unsupported audio devices and stale favorite-app paths.
- [ ] Decide whether quick-action menu items should perform asynchronous
  availability checks before selection. They currently remain selectable, open
  the feedback panel, and rely on the executor's live recheck and explanation.

### 4. Timer, settings, onboarding, and menu bar

- [x] Implement a one-to-180-minute countdown with remaining time, cancellation,
  persisted end date, restoration, and an optional local notification.
- [x] Request notification authorization only when starting a timer and keep the
  in-app timer running after denial.
- [x] Persist the settings model as JSON data in `UserDefaults` under
  `companionKit.settings.v1`.
- [x] Provide pet name, size, animation, reduced interaction, appearance,
  favorite app, clipboard snippet, launch-at-login toggle, position reset, and
  settings reset controls.
- [x] Provide three-page local/privacy/permission onboarding.
- [x] Provide menu-bar alternatives for pet visibility, actions, settings,
  animation, position reset, About, and Quit.
- [ ] Validate `SMAppService.mainApp` from a properly bundled application with a
  stable bundle identifier. Registration from `swift run` is not a supported
  release validation path and may fail or require approval in Login Items.
- [x] Make Reset All Settings cancel/reset the live timer and pending
  notification, disable launch at login when possible, restore defaults while
  preserving onboarding, reset position/appearance, and show the pet. A
  launch-item failure is reported after the remaining local reset completes.

### 5. Accessibility, privacy, and security

- [x] Add accessible labels, values, and hints for the pet and action rows.
- [x] Provide named controls, textual status alongside icons/colors, and a
  menu-bar alternative to precise pet interaction.
- [x] Avoid accounts, analytics, advertising, a CompanionKit backend, API keys,
  arbitrary scripts, hidden capture, and downloaded execution.
- [x] Keep notification text generic and clipboard access write-only and
  explicitly initiated.
- [x] Document the permission boundary and threat model.
- [ ] Complete and record manual VoiceOver, keyboard-only, visible-focus,
  contrast, larger-text, Reduce Motion, and permission-denial checks. No
  accessibility-conformance claim is currently made.
- [x] Enable the hardened-runtime build setting for Debug and Release app
  configurations.
- [ ] Decide App Sandbox policy and review the generated Info.plist, effective
  hardened-runtime signature, signing entitlements, and privacy strings in a
  signed archive.

### 6. Automated and local validation

- [x] Add a `CompanionKitTests` Swift Testing suite for registry de-duplication
  and categories, action availability/success/errors/confirmation, settings
  persistence/reset/corrupt data, timer transitions/restoration/notification
  denial/cancellation, and position clamping.
- [x] Compile the current fourteen-action test graph and pass all 28 tests in
  five suites using a temporary `/tmp` toolchain-compatibility workaround; no
  workaround artifacts were added to the repository.
- [x] Complete current-source SwiftPM Debug, Release, and
  `-strict-concurrency=complete` builds with an explicit macOS 15.4 SDK and
  redirected temporary caches; the strict-concurrency build reported no source
  warnings.
- [x] Re-run the standard `swift test --parallel` and authoritative unsigned
  `xcodebuild ... build`/`test` commands without compatibility overrides using
  Xcode 26.6; all 28 tests passed through both test paths.
- [x] Launch a current-source temporary QA `.app` and inspect onboarding, pet,
  all fourteen action rows, timer/settings links, Settings controls, and the
  exposed accessibility tree.
- [ ] Run real actions and complete permission-prompt, timer-restoration,
  multi-display, keyboard, VoiceOver, and login-item smoke tests.
- [ ] Inspect idle CPU/energy and task cancellation with Instruments; publish
  observations only after measurement.

Validation attempted on 2026-07-13:

- `swift --version` reported Apple Swift 6.3.3.
- `xcrun --sdk macosx --show-sdk-version` reported SDK 26.5.
- An initial attempt could not run `xcodebuild` because only Command Line Tools
  were selected and no full Xcode application was available.
- `swift build` did not reach source compilation. The installed compiler and SDK
  were built with different Swift patch versions (6.3.3 versus 6.3.2), and the
  managed environment also prevented SwiftPM/Clang cache writes outside the
  workspace.
- A later test-only workaround redirected caches/scratch data to `/tmp`, forced
  the SDK interface compiler version expected by the installed SDK, exposed the
  Command Line Tools Testing framework, and supplied its missing temporary
  interop shim. That run compiled the package and passed all 28 tests in five
  suites. It does not make the workaround a supported project requirement or
  validate a normal `swift build`/`swift test` invocation.
- Current-source SwiftPM Debug and Release builds succeeded with an explicit
  macOS 15.4 SDK and temporary cache/scratch paths. A complete
  strict-concurrency build also succeeded with no source warnings.
- A refreshed temporary QA app bundle launched successfully. Onboarding, the
  procedural pet, all fourteen action rows, timer/settings links, Settings
  controls, and their accessibility tree were inspected. Real actions,
  notification prompts, multiple displays, VoiceOver, and Launch at Login were
  not exercised.
- After Xcode 26.6 was installed and selected, the normal SwiftPM Debug and
  Release builds succeeded, `swift test --parallel` passed all 28 tests, and
  the authoritative unsigned Xcode Debug build and test commands both
  succeeded. The built app launched; onboarding, the pet, action panel, timer
  controls, and all Settings tabs were inspected through the accessibility
  tree. The Date and Time action executed successfully. Xcode logged one AppKit
  layout-recursion warning during the test-host launch; it remains to be
  investigated before release.

The current fourteen-action source now compiles and its unit suite passes under
the normal SwiftPM and authoritative unsigned Xcode project commands documented
in `docs/DEVELOPMENT.md`.

### 7. Distribution readiness

- [x] Add GitHub CI for debug build, tests, and release build on a hosted macOS
  runner, including unsigned Xcode project build/test checks.
- [x] Add repository governance, privacy, security, roadmap, and release
  documentation.
- [x] Configure current bundle identifier/version/build sources and the original
  application icon asset catalog.
- [ ] Confirm the release bundle identifier, signing team, sandbox decision, and
  entitlements before distribution.
- [ ] Produce and independently verify a signed, hardened, notarized archive.
- [ ] Test the public artifact on a clean supported Mac and publish checksums.

No binary release, signing, notarization, App Store listing, or Homebrew package
is represented as complete.

## Definition of done for the MVP

The source implementation alone is not the finish line. The MVP is ready to be
called complete only when package and test validation pass in a supported
toolchain, permission and accessibility behavior is manually checked,
documentation matches the resulting bundle, and release claims are limited to
work that was actually performed.
