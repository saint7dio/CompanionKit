import Foundation
@testable import CompanionKit

final class IsolatedUserDefaults {
    let suiteName: String
    let defaults: UserDefaults

    init(file: StaticString = #file, line: UInt = #line) {
        suiteName = "CompanionKitTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not create isolated UserDefaults", file: file, line: line)
        }
        self.defaults = defaults
        defaults.removePersistentDomain(forName: suiteName)
    }

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

@MainActor
final class WorkspaceSpy: WorkspaceServing {
    var openFinderCallCount = 0
    var openDownloadsCallCount = 0
    var openDocumentsCallCount = 0
    var openDesktopCallCount = 0
    var openApplicationsCallCount = 0
    var openSystemSettingsCallCount = 0
    var openedApplicationPaths: [String] = []
    var hideOtherApplicationsCallCount = 0

    var openFinderError: (any Error)?
    var hideOtherApplicationsError: (any Error)?

    func openFinder() async throws {
        openFinderCallCount += 1
        if let openFinderError { throw openFinderError }
    }

    func openDownloads() async throws {
        openDownloadsCallCount += 1
    }

    func openDocuments() async throws {
        openDocumentsCallCount += 1
    }

    func openDesktop() async throws {
        openDesktopCallCount += 1
    }

    func openApplications() async throws {
        openApplicationsCallCount += 1
    }

    func openSystemSettings() async throws {
        openSystemSettingsCallCount += 1
    }

    func openApplication(at path: String) async throws {
        openedApplicationPaths.append(path)
    }

    func hideOtherApplications() async throws {
        hideOtherApplicationsCallCount += 1
        if let hideOtherApplicationsError { throw hideOtherApplicationsError }
    }
}

@MainActor
final class ScreenshotSpy: ScreenshotServing {
    var openCallCount = 0

    func openScreenshotInterface() async throws {
        openCallCount += 1
    }
}

@MainActor
final class AudioStub: AudioServing {
    var available = true
    var increaseCallCount = 0
    var decreaseCallCount = 0
    var toggleMuteCallCount = 0
    var volume: Float = 0.5
    var muted = false

    func increaseVolume() throws -> Float {
        increaseCallCount += 1
        return volume
    }

    func decreaseVolume() throws -> Float {
        decreaseCallCount += 1
        return volume
    }

    func toggleMute() throws -> Bool {
        toggleMuteCallCount += 1
        return muted
    }

    func isAvailable() -> Bool {
        available
    }
}

@MainActor
final class ClipboardSpy: ClipboardServing {
    var copiedTexts: [String] = []

    func copy(_ text: String) throws {
        copiedTexts.append(text)
    }
}

@MainActor
final class NotificationServiceSpy: NotificationServing {
    var authorizationResult = true
    var requestAuthorizationCallCount = 0
    var scheduledIdentifiers: [String] = []
    var scheduledDates: [Date] = []
    var cancelledIdentifiers: [String] = []
    var schedulingError: (any Error)?

    func requestAuthorizationIfNeeded() async -> Bool {
        requestAuthorizationCallCount += 1
        return authorizationResult
    }

    func scheduleTimerNotification(identifier: String, at date: Date) async throws {
        if let schedulingError { throw schedulingError }
        scheduledIdentifiers.append(identifier)
        scheduledDates.append(date)
    }

    func cancel(identifier: String) {
        cancelledIdentifiers.append(identifier)
    }
}

@MainActor
final class LaunchAtLoginSpy: LaunchAtLoginServing {
    var isEnabled: Bool
    var hasRegistration: Bool
    var requestedValues: [Bool] = []

    init(isEnabled: Bool = false, hasRegistration: Bool = false) {
        self.isEnabled = isEnabled
        self.hasRegistration = hasRegistration
    }

    func setEnabled(_ enabled: Bool) throws {
        requestedValues.append(enabled)
        isEnabled = enabled
        hasRegistration = enabled
    }
}

@MainActor
final class ActionTestHarness {
    let storage: IsolatedUserDefaults
    let settings: SettingsStore
    let workspace = WorkspaceSpy()
    let screenshot = ScreenshotSpy()
    let audio = AudioStub()
    let clipboard = ClipboardSpy()

    init() {
        let storage = IsolatedUserDefaults()
        self.storage = storage
        settings = SettingsStore(defaults: storage.defaults)
    }

    var context: ActionContext {
        ActionContext(
            workspace: workspace,
            screenshot: screenshot,
            audio: audio,
            clipboard: clipboard,
            settings: settings
        )
    }

    func cleanUp() {
        storage.cleanUp()
    }
}

@MainActor
final class StubAction: CompanionAction {
    let id: String
    let title: String
    let description: String
    let systemImageName: String
    let category: ActionCategory
    let riskLevel: ActionRiskLevel
    let requiredCapabilities: Set<ActionCapability>
    let requiresConfirmation: Bool

    var availabilityValue: ActionAvailability
    var executeCallCount = 0
    var execution: @MainActor (ActionContext) async throws -> ActionResult

    init(
        id: String,
        title: String = "Test Action",
        category: ActionCategory = .productivity,
        riskLevel: ActionRiskLevel = .low,
        requiresConfirmation: Bool = false,
        availability: ActionAvailability = .available,
        execution: @escaping @MainActor (ActionContext) async throws -> ActionResult = { _ in
            .success("Done", message: "The action ran.")
        }
    ) {
        self.id = id
        self.title = title
        description = "A deterministic test action."
        systemImageName = "checkmark"
        self.category = category
        self.riskLevel = riskLevel
        requiredCapabilities = []
        self.requiresConfirmation = requiresConfirmation
        availabilityValue = availability
        self.execution = execution
    }

    func availability(in context: ActionContext) async -> ActionAvailability {
        availabilityValue
    }

    func execute(context: ActionContext) async throws -> ActionResult {
        executeCallCount += 1
        return try await execution(context)
    }
}
