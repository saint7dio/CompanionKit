# Permissions and System Capabilities

This document describes what the current CompanionKit source actually requests
or invokes. `CompanionKit.xcodeproj` is the authoritative native app project and
its shared scheme builds bundle identifier `org.companionkit.CompanionKit` with
a generated Info.plist and hardened-runtime build setting. The project has no App
Sandbox setting, signing team, or repository-owned entitlement file. Recheck the
effective signature, entitlements, Info.plist, and prompts against the final
signed app before release.

## Summary

| Permission or capability | Current feature | Runtime request by CompanionKit | Works if denied/unavailable? |
| --- | --- | --- | --- |
| Notifications (`alert`, `sound`) | Timer completion alert | Yes, contextually when a timer starts and status is not determined | Yes. Timer continues in the running app with a warning; no system alert is scheduled |
| Launch at Login (`SMAppService.mainApp`) | Optional startup toggle | User-controlled register/unregister call; this is not a TCC prompt | Yes. Launch manually; registration errors are shown |
| Accessibility | None | No request, no AX API use, and no Accessibility entitlement/configuration | Yes; all current features are designed without it |
| Screen Recording | None in CompanionKit | No. Screenshot action launches Apple's Screenshot app | Yes; the user/macOS decides whether and what to capture in the system app |
| Application/file selection | Favorite App and standard folders | `NSOpenPanel` for an app plus standard Downloads, Documents, Desktop, and Applications URLs; no broad file permission request in the current unsandboxed target | Yes. Only an affected action is unavailable/fails if its path cannot be used |
| Clipboard | Copy Saved Text | No macOS permission prompt; explicit write through `NSPasteboard` | Yes. Only the copy action fails if the write cannot complete |
| System audio | Volume and mute | No TCC prompt; uses Core Audio for the default output device | Yes. Actions are disabled when scalar volume is unreadable; write/mute failures can still be reported at execution |
| Application management | Hide Other Apps | No Accessibility or Apple Events request; uses `NSApplication.hideOtherApplications` | Yes. The rest of the app remains usable |

No source path requests camera, microphone, contacts, calendars, location, Full
Disk Access, Input Monitoring, Automation/Apple Events, or Accessibility. No
background screen capture, keystroke monitoring, clipboard reading/history, or
network listener is implemented.

## Notifications

**Feature:** Optional local alert when a countdown completes.

**Why:** A timer can finish while the pet/action popover is not visible.

**When requested:** `CountdownTimerController.start` first starts and persists
the timer, then asks `UNUserNotificationCenter` for current settings. It requests
`alert` and `sound` only when authorization is `.notDetermined`. Existing
authorized/provisional/ephemeral status is accepted; denied or unknown status is
not re-prompted.

**Data in the notification:** A generic title (“CompanionKit timer finished”)
and body (“Your countdown is complete.”). The pet name, clipboard snippet,
favorite-app path, and other preferences are not included.

**If denied:** The timer continues to count down while CompanionKit remains
running and the action panel shows that notifications are off. No unrelated
feature is disabled. A scheduled notification can complete even when the app is
not frontmost; the active timer end date also supports restoration after
relaunch.

**Cancellation:** Cancel Timer removes the pending request with identifier
`companionkit.timer`. Reset All Settings also cancels and resets the live timer,
removes the pending request, and clears the persisted end date.

**Review or revoke:** Open System Settings > Notifications > CompanionKit, or
use the “Open Notification Settings” button in CompanionKit Settings. Exact
labeling depends on the macOS version and installed build identity. Revocation
prevents future alerts but does not delete local preferences.

**Can the MVP operate without it?** Yes.

## Launch at Login

**Feature:** “Launch at login” toggle in Companion settings.

**Why:** Start the companion when the user signs in, only when explicitly
enabled.

**Implementation:** `LaunchAtLoginService` calls
`SMAppService.mainApp.register()` or `.unregister()` and reads
`SMAppService.mainApp.status` as the displayed source of truth. A successful
request also records the Boolean in local settings.

**Caveat:** This service is intended for a properly bundled application with a
stable identity. The Xcode target supplies the current bundle identifier, but
its login-item behavior has not been run locally or validated from a signed
archive. Behavior from the secondary `swift run` path is not release evidence;
registration may fail or macOS may require approval in System Settings. The UI
shows thrown failures and reports `.requiresApproval` as a typed permission
message instead of treating registration as enabled. Reset All Settings checks
for both enabled and pending-approval registrations and attempts to unregister
either state.

**Review, approve, or revoke:** Use System Settings > General > Login Items &
Extensions (wording may differ by macOS version), or turn the setting off in
CompanionKit if registration is functional. The app can always be launched
manually.

**Can the MVP operate without it?** Yes.

## Accessibility: not requested

CompanionKit currently does not use the macOS Accessibility (`AX`) APIs, prompt
for Accessibility access, or ship an Accessibility entitlement/configuration.
There is no active-window minimization/control feature. “Hide Other Apps” uses
the current application's public `NSApplication` operation and does not require
Accessibility access.

If a future action genuinely needs Accessibility, it must first add a narrow
service boundary, explain the exact effect before directing the user to System
Settings, check trust only in context, remain unavailable after denial, and
leave unrelated actions working. Documentation, threat model, tests, and final
bundle review must change in the same pull request.

## Screenshot interface: no direct capture permission

“Take a Screenshot” verifies and opens
`/System/Applications/Utilities/Screenshot.app` using `NSWorkspace`. CompanionKit
does not call a screen-capture API, choose a capture region, read the resulting
image, store screenshot history, or upload anything. Apple's Screenshot app and
macOS own any subsequent consent, destination, and retention behavior.

If Screenshot.app cannot be found or launched, only this action reports an
unavailable/system failure. CompanionKit does not request Screen Recording
access on its behalf.

## Files, applications, and workspace operations

- **Standard folders:** The app asks `FileManager` for the current user's
  Downloads, Documents, and Desktop URLs and the local-domain Applications URL,
  then asks `NSWorkspace` to open the selected folder. CompanionKit does not
  enumerate or read those folders' contents.
- **Favorite App:** A user explicitly selects one application with
  `NSOpenPanel`. CompanionKit stores its local path in `UserDefaults`, checks
  that the path exists, and asks `NSWorkspace.openApplication` to launch it.
- **Finder/System Settings:** Fixed system applications are launched through
  `NSWorkspace`.
- **Hide Other Apps:** Runs only after an explicit confirmation from the action
  panel. A menu quick-action redirects to that panel instead of bypassing the
  confirmation.

The current Xcode target is not App Sandbox-configured. Sandbox selection and any
future file access/security-scoped bookmark design must be decided and tested;
a stored plain path may not be sufficient for a sandboxed release.

## Clipboard

“Copy Saved Text” clears the general pasteboard and writes the configured
snippet after explicit activation. CompanionKit does not read the clipboard or
retain clipboard history. The snippet itself is stored as ordinary, unencrypted
local preference data; do not use it for passwords, tokens, or other secrets.
Other same-user applications may read clipboard content according to macOS
behavior.

## System audio

Volume Up, Volume Down, and Mute or Unmute use Core Audio on the current default
output device. They do not request microphone access and do not record audio.
The action panel checks whether scalar volume is readable before enabling these
actions. On a device without a dedicated mute property, mute stores the last
positive volume in process memory and sets volume to zero; unmute restores that
value (or a bounded default after relaunch). Device-specific property support
can still change between the check and execution, so failures are reported
rather than simulated.

The action row does not subscribe to default-audio-device changes. Reopening the
panel can refresh its displayed availability, and the executor/adapter recheck
before a side effect; a stale-looking enabled row can still end in a truthful
execution failure.

## Release permission audit

Before every release:

1. Inspect the final archive's effective entitlements and Info.plist.
2. Exercise first-use, denial, prior denial, revocation, and restricted-device
   paths for Notifications.
3. Validate login-item enable, required approval, disable, upgrade, and uninstall
   behavior from the signed application bundle.
4. Confirm the app does not appear in Accessibility or Screen Recording because
   of CompanionKit-owned requests.
5. Verify favorite-app and standard-folder behavior under the chosen sandbox
   policy.
6. Confirm clipboard and notification content contain no unexpected sensitive
   values.
7. Update this file, `../PRIVACY.md`, `THREAT_MODEL.md`, release notes, and tests
   for any permission/capability change.
