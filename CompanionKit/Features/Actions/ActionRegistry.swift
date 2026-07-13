import Combine
import Foundation

@MainActor
final class ActionRegistry {
    let actions: [any CompanionAction]

    init(actions: [any CompanionAction]) {
        var seen = Set<String>()
        self.actions = actions.filter { seen.insert($0.id).inserted }
    }

    func action(id: String) -> (any CompanionAction)? {
        actions.first { $0.id == id }
    }

    func actions(in category: ActionCategory) -> [any CompanionAction] {
        actions.filter { $0.category == category }
    }
}

enum ActionExecutionState: Equatable {
    case idle
    case running(actionID: String)
    case succeeded(ActionResult)
    case failed(title: String, message: String)
}

@MainActor
final class ActionExecutor: ObservableObject {
    @Published private(set) var state: ActionExecutionState = .idle
    private let context: ActionContext
    private let confirmationPolicy: ActionConfirmationPolicy

    convenience init(context: ActionContext) {
        self.init(context: context, confirmationPolicy: ActionConfirmationPolicy())
    }

    init(context: ActionContext, confirmationPolicy: ActionConfirmationPolicy) {
        self.context = context
        self.confirmationPolicy = confirmationPolicy
    }

    func availability(of action: any CompanionAction) async -> ActionAvailability {
        await action.availability(in: context)
    }

    @discardableResult
    func execute(_ action: any CompanionAction, confirmed: Bool = false) async -> ActionResult? {
        if case .running = state {
            return nil
        }
        let availability = await availability(of: action)
        guard availability.isAvailable else {
            state = .failed(
                title: action.title,
                message: availability.unavailableReason ?? "This action is unavailable."
            )
            return nil
        }

        let needsConfirmation = confirmationPolicy.requiresConfirmation(for: action)
        guard !needsConfirmation || confirmed else {
            state = .failed(title: action.title, message: "Confirmation is required before this action runs.")
            return nil
        }

        state = .running(actionID: action.id)
        do {
            let result = try await action.execute(context: context)
            state = .succeeded(result)
            return result
        } catch {
            let mapped = CompanionError.userFacing(error)
            state = .failed(title: action.title, message: mapped.localizedDescription)
            return nil
        }
    }

    func resetFeedback() {
        state = .idle
    }
}
