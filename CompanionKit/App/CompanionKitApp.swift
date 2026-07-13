import AppKit
import SwiftUI

@main
struct CompanionKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(environment: appDelegate.environment)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let environment = AppEnvironment()

    private var petWindowController: PetWindowController?
    private var statusItemController: StatusItemController?
    private var onboardingWindowController: OnboardingWindowController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let petController = PetWindowController(environment: environment)
        petWindowController = petController
        statusItemController = StatusItemController(environment: environment)

        environment.showActions = { [weak petController] in petController?.showActions() }
        environment.showPet = { [weak petController] in petController?.show() }
        environment.hidePet = { [weak petController] in petController?.hide() }
        environment.resetPetPosition = { [weak petController] in petController?.resetPosition() }
        environment.openSettings = { [weak self] in self?.showSettings() }

        if environment.settings.value.petVisible {
            petController.show()
        }

        if !environment.settings.value.onboardingCompleted {
            let onboarding = OnboardingWindowController { [weak self] in
                self?.environment.settings.update { $0.onboardingCompleted = true }
                self?.onboardingWindowController = nil
            }
            onboardingWindowController = onboarding
            onboarding.present()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(environment: environment)
        }
        settingsWindowController?.present()
    }
}
