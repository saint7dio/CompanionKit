# Accessibility

Accessibility is an acceptance requirement for CompanionKit, but this
pre-release repository does not claim WCAG conformance, complete VoiceOver
support, or suitability for a particular access need. The sections below
separate implemented source behavior from manual verification that remains.

## Implemented behavior

### More than pointer-only interaction

- Activating Veya opens the action popover, but the menu-bar item provides an
  alternative route to show/hide Veya, open actions and settings, run quick
  actions, manage the timer and personality, pause animations, reset position,
  and quit.
- Menu items use ordinary macOS menu semantics. Show/Hide Veya, Open Actions,
  Settings, and Quit have keyboard equivalents.
- The action panel, timer controls, Settings, onboarding, confirmation dialog,
  and footer use native SwiftUI/AppKit buttons, toggles, pickers, text fields,
  and menus.
- A menu-bar quick action opens the action panel before execution, keeping
  running/success/failure text available. Actions requiring confirmation open
  the panel without executing.
- Dragging is not the only way to manage position: Reset Veya Position is
  available in both Settings and the menu bar.

### VoiceOver semantics

- Veya is exposed as one button-like element with its configured personal name,
  canonical soul-companion identity, a default accessibility action, a
  state value such as “Ready” or “Action failed,” and a hint that describes the
  menu-bar alternative.
- Decorative pet and action-row symbols are hidden from accessibility.
- Every action row exposes its title as a label and either its description or
  unavailability reason as a hint.
- The countdown remaining time has a spoken “remaining” label and monospaced
  visible digits.
- The onboarding page count has an explicit “Page N of 4” label.
- The clipboard editor has a descriptive “Saved clipboard text” label.

### Motion and interaction

- `PetView` reads `accessibilityReduceMotion` and combines it with the one-way
  “Always reduce motion” preference. Effective Reduce Motion disables drift,
  aura pulse, particle orbit, local gaze movement, and state transition motion.
- The AppKit window controller observes macOS accessibility display-option
  changes and disables action-popover animation when Reduce Motion is active.
  The app's animation and reduced-interaction settings also disable repeating
  pet motion and popover animation, but the short pet-state transition is tied
  specifically to system Reduce Motion.
- “Enable subtle animations” pauses visual animation independently without
  changing semantic state. Sleeping remains a distinct semantic state.
- “Reduced interaction mode” suppresses hover reactions and the repeating float
  while preserving clicks and menu access.

### Status and color

- Running, success, and failure feedback includes an icon, title, and message;
  meaning is not carried by blue, green, or red alone.
- Veya state changes combine expression, shape, optional symbol, motion, and an
  accessibility value in addition to color.
- Disabled actions replace the description with an explanation and expose a
  disabled control state.
- The UI uses semantic system materials and colors so light and dark appearance
  can adapt to macOS.

## Known limitations

- A current-source temporary QA app exposed named onboarding, pet, all fourteen
  action rows, timer/settings links, and Settings controls in its accessibility
  tree. This was not a VoiceOver listening pass, Accessibility Inspector audit,
  keyboard-only test, contrast measurement, or assistive-technology
  compatibility report; those remain unverified.
- The borderless pet panel is nonactivating and the pet itself uses a tap
  gesture. It should not be treated as a reliable keyboard focus target; use
  the menu bar as the current keyboard alternative.
- Explicit focus-state styling and automated focus-order tests have not been
  added. Native controls provide platform focus rendering, but this still needs
  visual verification in the popover and Settings window.
- The action popover remains fixed-size; Settings and onboarding are resizable
  with minimum sizes. Very large text and long localized strings still require
  manual testing; the current source is English-only.
- Contrast of translucent Ethereal artwork, tertiary labels, material
  backgrounds, and status treatments has not been measured across appearances
  or increased-contrast settings.
- There are no automated UI or accessibility regression tests in the current
  package.

## Manual test guide

Run these checks on macOS 14 and a current macOS release using the Xcode-built
application target. Record macOS, Xcode, display settings, assistive technology,
and results; do not convert an unrecorded spot check into a support claim.

### Keyboard-only

1. Open the CompanionKit menu-bar menu without using the pointer.
2. Show and hide the pet, open the action interface, open Settings, and quit.
3. Traverse every action, the timer stepper/start/cancel controls, and footer
   controls with standard keyboard navigation.
4. Confirm the focused control is always visible and its order is logical.
5. Trigger Hide Other Apps and verify the confirmation can be understood,
   confirmed, and cancelled from the keyboard.
6. Verify disabled actions cannot run and their reason remains discoverable.

Enable “Keyboard navigation” in macOS Keyboard Settings if the test requires
full control traversal; record that setting with the result.

### VoiceOver

1. Start VoiceOver before launching the app and complete first-run onboarding.
2. Inspect the menu-bar item, pet element, action rows, Settings tabs, form
   controls, timer, status banners, and confirmation dialog.
3. Verify labels are concise, values update after action state changes, hints do
   not repeat labels, and decorative symbols are not announced.
4. Exercise an unavailable favorite app, unavailable audio output, failed
   action, successful action, notification denial, and timer cancellation.
5. Confirm no action depends on interpreting color, animation, or pet artwork.

### Motion and interaction settings

1. Enable macOS Reduce Motion before launch and while the app is running.
2. Verify floating, pulsing, and pet-state transition animations stop without
   hiding action results.
3. Toggle CompanionKit animation off/on and confirm the sleeping/ready state is
   announced.
4. Enable reduced-interaction mode and confirm hover/floating reactions stop
   while menu and click activation continue.
5. Verify the action popover does not animate while Reduce Motion is active, and
   note any remaining system/window transition that needs follow-up.

### Appearance, text, and contrast

1. Check System, Light, and Dark appearance settings.
2. Check Increase Contrast, Differentiate Without Color, display zoom, and the
   largest practical text/accessibility settings available on the test Mac.
3. Inspect status banners, disabled controls, tertiary labels, selected tabs,
   focus rings, and procedural pet details.
4. Test long pet names, long clipboard text, and long error messages for
   clipping or loss of controls.

### Pointer and displays

1. Confirm the pet can be dragged without requiring a small target.
2. Reset its position from Settings and the menu bar.
3. Move it across displays, disconnect the active display, and confirm it is
   clamped into the remaining visible frame.
4. Check full-screen Spaces and display scaling without claiming support until
   the observations are recorded.

## Reporting an accessibility issue

Use the accessibility issue template and include the affected revision, macOS
version, assistive technology/settings, expected behavior, and minimal
reproduction steps. Remove personal information from screenshots or recordings.
Security-sensitive behavior should be reported privately as described in
`../SECURITY.md`.
