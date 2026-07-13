import CoreGraphics
import Foundation
import Testing
@testable import CompanionKit

@Suite("Settings persistence")
@MainActor
struct SettingsStoreTests {
    @Test
    func testUpdatePersistsSettingsForANewStoreInstance() {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        let store = SettingsStore(defaults: storage.defaults)
        let timerEndDate = Date(timeIntervalSince1970: 1_900_000_000)

        store.update {
            $0.petName = "Mochi"
            $0.petSize = .large
            $0.lastPetOrigin = StoredPoint(CGPoint(x: 123, y: 456))
            $0.animationEnabled = false
            $0.preferredApplicationPath = "/Applications/Notes.app"
            $0.preferredAppearance = .dark
            $0.clipboardSnippet = "Focus time"
            $0.onboardingCompleted = true
            $0.activeTimerEndDate = timerEndDate
            $0.theme = .ethereal
            $0.baseColor = .mistMint
            $0.auraIntensity = .subtle
            $0.particleIntensity = .off
            $0.personality = .calm
            $0.reduceMotionOverride = true
        }

        let reloaded = SettingsStore(defaults: storage.defaults)

        #expect(reloaded.value.petName == "Mochi")
        #expect(reloaded.value.petSize == .large)
        #expect(reloaded.value.lastPetOrigin == StoredPoint(CGPoint(x: 123, y: 456)))
        #expect(!reloaded.value.animationEnabled)
        #expect(reloaded.value.preferredApplicationPath == "/Applications/Notes.app")
        #expect(reloaded.value.preferredAppearance == .dark)
        #expect(reloaded.value.clipboardSnippet == "Focus time")
        #expect(reloaded.value.onboardingCompleted)
        #expect(reloaded.value.activeTimerEndDate == timerEndDate)
        #expect(reloaded.value.theme == .ethereal)
        #expect(reloaded.value.baseColor == .mistMint)
        #expect(reloaded.value.auraIntensity == .subtle)
        #expect(reloaded.value.particleIntensity == .off)
        #expect(reloaded.value.personality == .calm)
        #expect(reloaded.value.reduceMotionOverride)
        #expect(storage.defaults.data(forKey: SettingsStore.storageKey) != nil)
    }

    @Test
    func testResetRestoresDefaultsWhilePreservingOnboardingByDefault() {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        let store = SettingsStore(defaults: storage.defaults)
        store.update {
            $0.petName = "Changed"
            $0.petVisible = false
            $0.clipboardSnippet = "Changed"
            $0.onboardingCompleted = true
        }

        store.reset()

        var expected = CompanionSettings.defaults
        expected.onboardingCompleted = true
        #expect(store.value == expected)
        #expect(SettingsStore(defaults: storage.defaults).value == expected)
    }

    @Test
    func testResetCanClearOnboardingCompletion() {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        let store = SettingsStore(defaults: storage.defaults)
        store.update {
            $0.petName = "Changed"
            $0.onboardingCompleted = true
        }

        store.reset(preservingOnboarding: false)

        #expect(store.value == .defaults)
        #expect(SettingsStore(defaults: storage.defaults).value == .defaults)
    }

    @Test
    func testInvalidPersistedDataFallsBackToDefaults() {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        storage.defaults.set(Data("not-json".utf8), forKey: SettingsStore.storageKey)

        let store = SettingsStore(defaults: storage.defaults)

        #expect(store.value == .defaults)
    }

    @Test
    func testDefaultsUseCanonicalVeyaEtherealIdentity() {
        let defaults = CompanionSettings.defaults

        #expect(defaults.petName == "Veya")
        #expect(defaults.theme == .ethereal)
        #expect(defaults.baseColor == .iceBlue)
        #expect(defaults.personality == .friendly)
        #expect(!defaults.reduceMotionOverride)
    }

    @Test
    func testLegacyPipSettingsMigrateToVeyaAndNewDefaults() {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        storage.defaults.set(Data(#"{"petName":"Pip","animationEnabled":true}"#.utf8), forKey: SettingsStore.storageKey)

        let store = SettingsStore(defaults: storage.defaults)

        #expect(store.value.petName == "Veya")
        #expect(store.value.theme == .ethereal)
        #expect(store.value.personality == .friendly)
        #expect(store.value.auraIntensity == .standard)
    }

    @Test
    func testResetDisablesPendingLaunchAtLoginRegistration() throws {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        let settings = SettingsStore(defaults: storage.defaults)
        let notifications = NotificationServiceSpy()
        let launchAtLogin = LaunchAtLoginSpy(isEnabled: false, hasRegistration: true)
        let environment = AppEnvironment(
            settings: settings,
            workspace: WorkspaceSpy(),
            screenshot: ScreenshotSpy(),
            audio: AudioStub(),
            clipboard: ClipboardSpy(),
            notifications: notifications,
            launchAtLogin: launchAtLogin
        )

        try environment.resetAllSettings()

        #expect(launchAtLogin.requestedValues == [false])
        #expect(!launchAtLogin.hasRegistration)
        #expect(settings.value == .defaults)
    }
}
