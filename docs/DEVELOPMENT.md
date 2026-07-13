# CompanionKit Development Guide

## Prerequisites

- macOS 14 or later.
- Xcode 16 or later with a macOS 14+ SDK. The project uses Xcode 16 project
  features; keep the selected compiler and SDK from the same installation.
- Git.

The Xcode application and test targets compile in Swift 5 mode and target macOS
14. The secondary package declares Swift tools 6.0, macOS 14, and Swift language
mode 5. There are no external package dependencies, no required API keys, and no
paid Apple Developer membership requirement for unsigned local builds/tests.

## Authoritative project and Xcode status

`CompanionKit.xcodeproj` is authoritative for the native app bundle, resources,
generated Info.plist, local Run action, tests, profiling, and archives. The
repository-owned shared scheme is `CompanionKit`. It contains:

- application target/product: `CompanionKit` / `CompanionKit.app`;
- unit-test target: `CompanionKitTests`;
- current app/test bundle identifiers: `org.companionkit.CompanionKit` and
  `org.companionkit.CompanionKitTests`;
- marketing/build versions: `0.1.0` / `1`;
- macOS deployment target 14.0 and Swift 5 language mode;
- generated Info.plist with `LSUIElement=YES`;
- `AppIcon` and `AccentColor` asset catalog settings;
- automatic signing style and hardened-runtime build setting, but no development
  team, App Sandbox setting, or repository-owned entitlements file.

`Package.swift` remains a supported secondary command-line build/test path over
the same source and test directories. It does not create the app bundle identity
or compile the asset catalog, so it is not authoritative for Launch at Login,
signing, resources, archive, or distribution behavior.

## Project map

```text
CompanionKit.xcodeproj/    # authoritative native project and shared scheme
Package.swift             # secondary SwiftPM build/test path
CompanionKit/
├── App/                 # lifecycle and dependency composition
├── Core/
│   ├── Errors/          # typed user-facing errors
│   ├── Models/          # pet, action, and persisted values
│   ├── Protocols/       # action and service boundaries
│   ├── Services/        # local settings store
│   └── Utilities/       # clamping and design-system helpers
├── Features/
│   ├── Actions/         # built-ins, registry, executor, action UI
│   ├── MenuBar/         # status item and quick actions
│   ├── Onboarding/      # first-run explanation
│   ├── Pet/             # procedural pet renderer
│   ├── Settings/        # customization and privacy UI
│   └── Timer/           # countdown state machine/controller
├── Platform/macOS/      # AppKit windows and live OS adapters
└── Resources/           # original app icon and accent-color asset catalog
CompanionKitTests/       # Swift Testing unit suite for both build systems
docs/                    # architecture, permission, quality, release guidance
```

See `ARCHITECTURE.md` for dependency direction and runtime flow.

## Build, test, and run

### Authoritative Xcode project

From the repository root, reproduce the unsigned CI build and tests:

```sh
xcodebuild \
  -project CompanionKit.xcodeproj \
  -scheme CompanionKit \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project CompanionKit.xcodeproj \
  -scheme CompanionKit \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

To run interactively, open `CompanionKit.xcodeproj`, select the shared
`CompanionKit` scheme and “My Mac,” then choose Product > Run. Xcode may use a
local ad-hoc “Sign to Run Locally” identity; no Apple Developer team is checked
in.

### Secondary Swift Package

The supported CLI checks are:

```sh
swift package resolve
swift build --configuration debug
swift test --parallel
swift build --configuration release
swift run CompanionKit
```

`swift run CompanionKit` is a development convenience. It does not validate a
distributable `.app`, Launch at Login, application identity, code signing,
entitlements, hardened runtime, archiving, or notarization.

CI runs both sets: SwiftPM debug/test/release plus unsigned Xcode Debug
build/test on a hosted macOS runner. A configured workflow is not evidence that
CI has passed until its actual run is inspected.

### Local archive

This command can exercise the archive graph without signing:

```sh
xcodebuild \
  -project CompanionKit.xcodeproj \
  -scheme CompanionKit \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$PWD/build/CompanionKit.xcarchive" \
  CODE_SIGNING_ALLOWED=NO \
  archive
```

An unsigned local archive is not distributable and does not prove the effective
hardened-runtime signature. A release archive requires a reviewed Developer ID
signing configuration, effective entitlements inspection, notarization, and the
checks in `RELEASE.md`.

### Observed local validation history

On 2026-07-13 the available managed environment initially reported Apple Swift 6.3.3 and
macOS SDK 26.5 built with Swift 6.3.2. `xcodebuild` was unavailable because only
Command Line Tools were selected and no full Xcode app was installed.
`swift build` stopped while compiling the package manifest because the compiler
and SDK patch versions did not match; managed cache directories were also not
writable. No CompanionKit source file was compiled in that initial attempt. The
Xcode build/test commands could not be run because full Xcode was absent.

A subsequent diagnostic SwiftPM test run redirected all caches/scratch files to
`/tmp`, forced the SDK's expected interface-compiler version, added the Command
Line Tools Testing framework search paths, and supplied a missing temporary
`lib_TestingInterop` shim under `/tmp`. That workaround compiled the test graph
and passed all 28 tests in five suites. It changed no repository file, but it is
not a supported developer setup and must not be copied into CI or project build
settings. At that point, normal `swift build`/`swift test` and the authoritative
Xcode build/test commands still needed validation with one matching full Xcode
installation.

The current fourteen-action source passed SwiftPM Debug and Release builds with
an explicit macOS 15.4 SDK, a `-strict-concurrency=complete` build without source
warnings, and all 28 tests. A refreshed temporary QA app launched and exposed
onboarding, pet, all fourteen action rows, timer/settings links, Settings
controls, and the expected accessibility tree. No run has validated real
actions, permission prompts, notification delivery, timer restoration, multiple
displays, keyboard-only use, VoiceOver, Launch at Login, signing, or the Xcode
project in that earlier run.

Later on 2026-07-13, Xcode 26.6 was installed and selected with Swift 6.3.3 and
the macOS 26.5 SDK. The normal SwiftPM Debug and Release builds succeeded,
`swift test --parallel` passed all 28 tests, and the documented unsigned Xcode
Debug build and test commands both succeeded. The resulting native app launched
and its onboarding, pet, action panel, timer controls, and all Settings tabs
were inspected through the accessibility tree; the Date and Time action also
completed successfully. The Xcode test-host launch emitted an AppKit
layout-recursion warning that needs investigation. Permission prompts,
notification delivery, timer restoration, multiple displays, keyboard-only
use, VoiceOver, Launch at Login, signing, and notarization remain unvalidated.

After the V2 Soul-Orb implementation on the same date, normal SwiftPM Debug and
Release builds succeeded and `swift test --parallel` passed all 36 tests in six
suites. The documented unsigned Xcode Debug build and test commands also
succeeded with all 36 tests. The Veya renderer, Ethereal customization,
semantic states, timer presets, onboarding, and refreshed app icon were then
inspected in the locally launched application. This is local engineering
validation only: manual VoiceOver, multiple-display, real permission-denial,
notification restoration, signing, notarization, and distribution checks are
still pending.

On a development Mac, select the matching full Xcode and verify:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcodebuild -version
swift --version
xcrun --sdk macosx --show-sdk-version
```

Only run the `sudo xcode-select` command on a machine you administer and after
confirming the Xcode path. Changing the active developer directory is a machine
configuration change, not a repository fix.

## Linting and formatting

No SwiftLint, SwiftFormat, or other lint/format tool is configured. Do not add a
CI or contribution requirement for an unconfigured global tool. Use Xcode's
standard indentation, match adjacent source, keep types focused, and rely on
compiler warnings plus review until a formatter/linter is intentionally adopted
with configuration and CI.

## Debugging

### Application lifecycle and windows

The app sets accessory activation policy, so it does not behave like a normal
Dock application. Use the menu-bar soul-orb item to reopen actions or Settings
if Veya is hidden. Placement is persisted in `UserDefaults`; use Reset Veya
Position rather than manually editing preferences during ordinary testing.

Inspect `PetWindowController` for panel, popover, screen selection, and clamping
issues. Exercise display connection/disconnection rather than assuming the main
screen remains constant.

### Settings

`SettingsStore.storageKey` is `companionKit.settings.v1`. The value is one JSON
blob in standard `UserDefaults`. Unit tests should use an isolated suite and
remove its persistent domain during teardown. Never print clipboard snippets or
selected personal paths into diagnostics.

The in-app reset preserves onboarding completion while cancelling/resetting the
timer and pending notification, attempting to disable launch at login, restoring
appearance and position defaults, and showing the pet. For the current Xcode app
identity, a developer who intentionally needs a complete first-run reset can
quit CompanionKit and remove only its settings blob:

```sh
defaults delete org.companionkit.CompanionKit companionKit.settings.v1
```

The bundle identifier is pre-release configuration and may change. Confirm it
in the project before using the command; the SwiftPM executable may use a
different preferences domain.

### Actions

Watch `ActionExecutor.state` for idle/running/success/failure transitions.
Availability is asynchronous and is rechecked immediately before execution.
While one action is running, later execution calls return without starting a
second service operation. Platform failures should enter through
`CompanionError`, not be swallowed or reported as success.

Audio behavior varies by output device. Test a device with writable scalar
volume, a device without it if available, mute-property fallback, and a default
device change between availability and execution. The no-mute-property fallback
remembers the prior volume only for the current process, so also test relaunch
after a fallback mute.

### Timer and notifications

The controller ticks once per second only while running and persists an absolute
end date. Test start, foreground completion, cancellation, relaunch before end,
relaunch after end, denied notifications, revoked notifications, and scheduling
failure. Notification content should remain generic.

### Performance

Use Instruments in a full Xcode environment to inspect Time Profiler, Energy
Log, allocations, task lifetime, and idle wakeups. Measure with no timer, a
running timer, animation enabled/disabled, the popover closed/open, and the pet
hidden. Record the hardware, macOS/build, duration, and observations. Do not
publish performance numbers that were not measured.

## Adding a deterministic action

1. Decide whether the action belongs in the MVP and can be implemented with a
   public, narrow macOS API. Arbitrary shell, user-authored AppleScript,
   downloaded execution, unsafe dynamic loading, hidden capture, credential
   collection, and unbounded automation are prohibited.
2. Reuse an existing Core service protocol or add the smallest new protocol in
   `CompanionKit/Core/Protocols/Services.swift`. Put the live OS implementation
   under `CompanionKit/Platform/macOS` and inject it through `AppEnvironment`.
3. Construct a `BuiltInAction` (or a small conforming type) with a stable ID,
   user-visible title/description, SF Symbol, category, capabilities, risk,
   explicit confirmation requirement, availability check, and structured
   result.
4. Register it in `BuiltInActionFactory.makeActions`. Do not bypass the registry
   with a UI-only OS call.
5. Recheck availability and authorization at execution time. Never simulate
   success after an adapter failure.
6. Add focused tests for registry lookup, availability, success, typed failure,
   denial, and confirmation. Use the shared `ActionConfirmationPolicy` from the
   action panel, menu, and executor; do not add a second presentation-only rule.
7. Update architecture, permissions, privacy, threat model, accessibility, and
   user documentation as affected.

## Adding a pet appearance

The current pet is one procedural SwiftUI composition inside `PetView`; there is
no appearance catalog or renderer protocol. Before adding a second pet, extract
a small renderer/configuration boundary that consumes `PetVisualState` and size
without moving window, action, or persistence policy into the renderer.

Use original/repository-owned vector shapes, SwiftUI drawing, or SF Symbols.
Document asset provenance. New motion must respect Reduce Motion, the app's
animation setting, and reduced-interaction mode; each state must have a
non-color-only and accessible representation.

## Testing permissions safely

- Prefer a dedicated local development bundle identity for destructive
  permission testing; do not repeatedly alter permissions for a production
  build.
- For Notifications, test not-determined authorization, allow, deny, previously
  denied, revoke while running, cancellation, and app relaunch. Use System
  Settings to review/reset access and avoid scripts that change unrelated TCC
  records.
- For Launch at Login, test only a properly bundled app. Verify enable, any
  System Settings approval, launch after sign-in, disable, update, and removal.
- Do not add or grant Accessibility/Screen Recording merely to make current
  actions work. Current CompanionKit code requests neither.
- Use fake `NotificationServing`, `LaunchAtLoginServing`, and other protocols in
  unit tests; keep real permission prompts out of the automated suite.
- Never commit local preferences, notification screenshots with personal data,
  provisioning files, or signing credentials.

## Common issues

### `xcodebuild` says Command Line Tools is active

Install/select a full compatible Xcode. A Command Line Tools-only environment
cannot open/run the app as an Xcode application project and may pair an
incompatible compiler and SDK.

### Compiler says the SDK is unsupported

The selected Swift compiler and SDK came from different releases. Select one
complete Xcode toolchain; do not patch generated module interfaces or vendor SDK
files into the repository.

### Launch at Login fails

Confirm you are running a bundled app with a stable identity and inspect General
> Login Items. `swift run` is not a supported launch-item validation context.
The Xcode project exists, but login-item enable/approval/disable still needs
validation from a locally signed, installed app and later from the release
candidate.

### Favorite App is unavailable after the app moved

Choose the application again in Settings. The current preference stores a plain
path, not a security-scoped bookmark.

### Audio controls are disabled

The default output device may not expose readable scalar volume, in which case
the actions are disabled. Readable-but-not-settable devices can remain enabled
until execution reports the write failure. The row does not live-refresh on an
output-device change, so reopen the panel while testing; never assume success.

### Timer works but no notification appears

Check the warning in the action panel and System Settings > Notifications.
Denial is expected to leave the in-app timer functional.
