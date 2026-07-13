import Foundation

@MainActor
protocol CompanionAction: AnyObject {
    var id: String { get }
    var title: String { get }
    var description: String { get }
    var systemImageName: String { get }
    var category: ActionCategory { get }
    var riskLevel: ActionRiskLevel { get }
    var requiredCapabilities: Set<ActionCapability> { get }
    var requiresConfirmation: Bool { get }

    func availability(in context: ActionContext) async -> ActionAvailability
    func execute(context: ActionContext) async throws -> ActionResult
}

enum ActionCategory: String, CaseIterable, Identifiable, Sendable {
    case places
    case system
    case productivity

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

@MainActor
struct ActionContext {
    let workspace: any WorkspaceServing
    let screenshot: any ScreenshotServing
    let audio: any AudioServing
    let clipboard: any ClipboardServing
    let settings: SettingsStore
}

@MainActor
struct ActionConfirmationPolicy {
    func requiresConfirmation(for action: any CompanionAction) -> Bool {
        action.requiresConfirmation || action.riskLevel == .high
    }
}
