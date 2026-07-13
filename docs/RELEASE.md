# Release Guide

CompanionKit has not yet published a signed or notarized release. This document
is a future maintainer checklist; completing a local build is not permission to
claim that distribution requirements have been met.

## Release prerequisites

Before the first release, confirm and document:

- canonical repository URL and release owner;
- final application bundle identifier;
- authoritative Xcode project/workspace and shared application scheme;
- marketing version and build-number sources;
- minimum supported macOS and Xcode versions;
- App Sandbox decision, entitlements, and Info.plist usage descriptions;
- Apple Developer team, Developer ID Application certificate, and notarization
  credentials stored outside the repository;
- monitored private security and community contact paths;
- license provenance for every bundled asset and dependency;
- supported CPU architectures and distribution archive format.

Do not commit certificates, private keys, passwords, App Store Connect API keys,
notarization profiles, provisioning profiles containing personal data, or
unredacted build logs.

## Prepare the release

1. Choose a Semantic Versioning-compatible version appropriate to the actual
   compatibility and maturity.
2. Freeze release scope and ensure the implementation plan and roadmap reflect
   reality.
3. Update application marketing version/build number in the authoritative
   project settings.
4. Move relevant `CHANGELOG.md` entries from **Unreleased** into a dated version
   section. Update its comparison links after the canonical repository URL is
   known.
5. Verify README feature, requirement, permission, privacy, and limitation
   claims against the release candidate.
6. Review `PRIVACY.md`, `SECURITY.md`, `docs/PERMISSIONS.md`,
   `docs/ACCESSIBILITY.md`, and `docs/THREAT_MODEL.md` against source,
   entitlements, and runtime behavior.
7. Confirm third-party notices and asset licenses, if any.
8. Create a release branch only if the repository's maintainers use that
   workflow; otherwise prepare a reviewed release pull request.

## Validate source

From a clean checkout, run the currently supported package checks:

```sh
swift package resolve
swift build --configuration debug
swift test --parallel
swift build --configuration release
```

Build and test the authoritative Xcode project and checked-in shared scheme:

```sh
xcodebuild \
  -project CompanionKit.xcodeproj \
  -scheme CompanionKit \
  -configuration Release \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  clean build

xcodebuild \
  -project CompanionKit.xcodeproj \
  -scheme CompanionKit \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Also verify:

- no unexpected build warnings;
- all required tests pass on the minimum supported macOS and a current macOS;
- first-run, upgrade, reset, and denied-permission paths;
- multiple displays and display removal;
- light/dark appearance, keyboard-only use, VoiceOver, Reduce Motion, and
  relevant larger-text settings;
- idle CPU/energy behavior with Instruments (record observations, not invented
  benchmark claims);
- no unexpected outbound connections or sensitive log content;
- all action success and failure messages reflect actual system results.

Record exact commands, Xcode/Swift versions, destinations, and results in the
release pull request.

## Archive and sign

Use Xcode Organizer or a documented `xcodebuild archive` command with the final
shared scheme. Export using the intended Developer ID distribution method.

Check the archive before distribution:

```sh
codesign --verify --deep --strict --verbose=2 /path/to/CompanionKit.app
spctl --assess --type execute --verbose=2 /path/to/CompanionKit.app
```

Review the effective signature and entitlements:

```sh
codesign --display --verbose=4 /path/to/CompanionKit.app
codesign --display --entitlements :- /path/to/CompanionKit.app
```

Use `--deep` for verification only; do not use recursive signing as a substitute
for a correct signing graph. Never disable hardened runtime merely to make a
release pass.

## Notarize and staple

Submit the final ZIP, DMG, or PKG with Apple's current `notarytool` workflow and
a Keychain profile configured outside source control. Wait for acceptance,
staple the ticket to the distributable where supported, and re-run Gatekeeper
assessment on a clean machine or VM.

Save the submission identifier and outcome in private release records. Do not
publish credential-bearing commands or logs. Do not describe an artifact as
notarized until Apple has accepted it and stapling/assessment have been
verified.

## Publish

1. Produce the final archive from the reviewed tag commit.
2. Generate SHA-256 checksums, for example:

   ```sh
   shasum -a 256 CompanionKit-<version>.zip
   ```

3. Tag the exact commit using the repository's chosen signed-tag policy.
4. Draft a GitHub release with user-facing highlights, requirements,
   permissions, known limitations, upgrade notes, changelog link, and checksum.
5. Upload only the verified signed/notarized artifact and related checksum.
6. Have a second maintainer compare the tag, artifact, signature, checksum, and
   release notes where practical.
7. Publish, then test the public download on a clean supported Mac.
8. Update documentation links and keep the previous supported release available
   according to the security policy.

Do not publish a deployment workflow that requires undocumented secrets. GitHub
release automation should be added only after the signing and approval model is
designed and reviewed.

## After release

- Monitor private security reports and public issues.
- Triage regressions without requesting sensitive user data.
- Document any known issue and safe workaround.
- Prepare a patch release for security or serious correctness problems.
- Update supported versions in `SECURITY.md` when support policy changes.
- Add the next empty **Unreleased** section to `CHANGELOG.md` if needed.

## Release sign-off

- [ ] Version/build numbers and tag agree.
- [ ] Changelog and release notes are complete.
- [ ] Clean-checkout build and tests passed; results are recorded.
- [ ] Manual accessibility and permission checks were performed.
- [ ] Privacy, security, entitlements, data storage, and network behavior were
      reviewed.
- [ ] Assets and dependencies have compatible licenses.
- [ ] Archive is signed with the intended identity and hardened runtime.
- [ ] Notarization is accepted, stapled where supported, and Gatekeeper-tested.
- [ ] SHA-256 checksum matches the uploaded artifact.
- [ ] Public artifact was installed and launched on a clean supported Mac.
- [ ] No secret or personal signing material appears in source, artifacts, or
      published logs.
