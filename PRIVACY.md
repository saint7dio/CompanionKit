# CompanionKit Privacy Notice

Last updated: 2026-07-13

CompanionKit is designed as a local-first macOS application. This notice
describes the MVP source code and intended behavior; it does not describe
unimplemented roadmap features or independently distributed third-party
builds.

## Summary

- No CompanionKit account is required.
- The MVP has no advertising or analytics.
- The MVP is not designed to upload settings, action history, clipboard
  content, screenshots, or usage data.
- Settings are stored locally using macOS preferences (`UserDefaults`).
- Optional macOS permissions are requested in context for the feature that
  needs them.

CompanionKit can open macOS or third-party applications. Those applications and
macOS services have their own privacy practices, which CompanionKit does not
control.

## Data stored on the Mac

The settings model may store:

- Veya’s personal name, size, Ethereal theme/color, aura and particle
  intensities, personality, app appearance, visibility, motion preferences,
  and last screen position;
- onboarding and reduced-interaction preferences;
- launch-at-login preference;
- the path to a user-selected preferred application;
- a user-configured clipboard snippet;
- the end date of an active timer so it can be restored;
- other explicit preferences added and documented by a future version.

The current settings store encodes these values under the local preferences key
`companionKit.settings.v1`. A selected application path and clipboard snippet
can themselves reveal personal information; users should avoid putting secrets
in either value.

CompanionKit does not intentionally retain action history. A user-triggered
screenshot is handed to the macOS screenshot interface; the destination and
retention are controlled by the user and macOS rather than by CompanionKit.
The MVP does not provide screenshot history or background capture.

## Permissions and system capabilities

The current source uses the following optional permission or system capability:

| Permission or capability | Why it may be used | When requested | Behavior when denied |
| --- | --- | --- | --- |
| Notifications | Notify the user when a local timer finishes | Contextually when the user starts a timer | The timer continues in-app with a warning |
| Accessibility | Not used by the MVP | Never requested | All current features remain available subject to their own capabilities |
| Screen Recording | Not used directly; the screenshot action opens Apple's visible Screenshot app | Never requested by CompanionKit | The user and Screenshot app control any later capture |
| Launch at Login | Register CompanionKit with the public macOS login-item service | When the user enables the setting | The app can still be launched manually |

Opening Finder, Downloads, Documents, Desktop, Applications, System Settings,
or a user-selected application does not by itself give CompanionKit
unrestricted access to those applications or folders. CompanionKit does not
enumerate the contents of the standard folders it asks Finder to display.

See `docs/PERMISSIONS.md` for feature-by-feature guidance. **Release
verification required:** confirm this table against the final entitlements,
Info.plist usage descriptions, and runtime permission prompts before each
release.

## Information leaving the Mac

The MVP design has no CompanionKit backend, account service, analytics SDK,
advertising SDK, or mandatory network request. CompanionKit does not sell user
data.

This statement does not cover:

- network activity performed by macOS, an application the user opens, or a
  distribution service;
- GitHub activity when a user visits this repository or submits an issue;
- modified third-party builds.

Future optional network or AI features must remain clearly separated from the
MVP, require an explicit user choice, and update this notice before release.

## Deleting local data

Use CompanionKit's Reset All Settings control to restore defaults, cancel the
active timer notification, and attempt to disable Launch at Login. Removing the
app may not automatically remove macOS preference data. The current pre-release
bundle identifier is `org.companionkit.CompanionKit`; confirm it in the installed
build before using a manual `defaults delete` command because it may change.

Users can revoke Notifications and Login Item access in System Settings.
CompanionKit does not request Accessibility or Screen Recording. Revoking a
capability does not necessarily erase the local settings described above.

## Diagnostics

Debug builds may write ordinary developer diagnostics to local macOS logs. Do
not intentionally log clipboard snippets, selected paths, screenshots, or other
sensitive content. No crash-reporting or remote-log service is configured by
the MVP unless a future release notice explicitly says otherwise.

## Changes to this notice

Material changes to storage, permissions, dependencies, or network behavior
must update this file and the changelog in the same pull request.

## Contact

Privacy questions may be raised in a public issue only when they contain no
personal or security-sensitive information. For vulnerabilities, follow
[SECURITY.md](SECURITY.md). **Before public release, the repository owner should
publish a monitored private contact method.**
