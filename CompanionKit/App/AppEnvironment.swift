import AppKit
import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let settings: SettingsStore
    let registry: ActionRegistry
    let confirmationPolicy: ActionConfirmationPolicy
    let executor: ActionExecutor
    let timer: CountdownTimerController
    let launchAtLogin: any LaunchAtLoginServing

    @Published private(set) var petState: CompanionState = .idle

    var showActions: () -> Void = {}
    var showPet: () -> Void = {}
    var hidePet: () -> Void = {}
    var resetPetPosition: () -> Void = {}
    var openSettings: () -> Void = {}

    private var cancellables = Set<AnyCancellable>()
    private var feedbackResetTask: Task<Void, Never>?
    private var companionStateMachine = CompanionStateMachine()

    init(
        settings: SettingsStore? = nil,
        workspace: (any WorkspaceServing)? = nil,
        screenshot: (any ScreenshotServing)? = nil,
        audio: (any AudioServing)? = nil,
        clipboard: (any ClipboardServing)? = nil,
        notifications: (any NotificationServing)? = nil,
        launchAtLogin: (any LaunchAtLoginServing)? = nil
    ) {
        let settingsStore = settings ?? SettingsStore()
        let notificationService = notifications ?? LocalNotificationService()
        let context = ActionContext(
            workspace: workspace ?? LiveWorkspaceService(),
            screenshot: screenshot ?? LiveScreenshotService(),
            audio: audio ?? CoreAudioService(),
            clipboard: clipboard ?? LiveClipboardService(),
            settings: settingsStore
        )

        self.settings = settingsStore
        let policy = ActionConfirmationPolicy()
        confirmationPolicy = policy
        registry = ActionRegistry(actions: BuiltInActionFactory.makeActions())
        executor = ActionExecutor(context: context, confirmationPolicy: policy)
        timer = CountdownTimerController(settings: settingsStore, notifications: notificationService)
        self.launchAtLogin = launchAtLogin ?? LaunchAtLoginService()

        observeExecutionState()
        observeTimerState()
        applyAppearance()
    }

    func setPetAttention(_ active: Bool) {
        guard !settings.value.reducedInteractionMode else { return }
        companionStateMachine.setHovering(active)
        publishCompanionState()
    }

    func setPetVisibility(_ visible: Bool) {
        visible ? companionStateMachine.show() : companionStateMachine.hide()
        publishCompanionState()
    }

    func setCompanionState(_ state: CompanionState) {
        companionStateMachine.transition(to: state)
        publishCompanionState()
    }

    func setAnimationsEnabled(_ enabled: Bool) {
        settings.update { $0.animationEnabled = enabled }
    }

    func applyAppearance() {
        guard let application = NSApp else { return }
        switch settings.value.preferredAppearance {
        case .system:
            application.appearance = nil
        case .light:
            application.appearance = NSAppearance(named: .aqua)
        case .dark:
            application.appearance = NSAppearance(named: .darkAqua)
        }
    }

    func resetAllSettings() throws {
        timer.cancel()
        timer.reset()

        var launchError: Error?
        if launchAtLogin.hasRegistration {
            do {
                try launchAtLogin.setEnabled(false)
            } catch {
                launchError = error
            }
        }

        settings.reset()
        companionStateMachine.transition(to: .idle)
        publishCompanionState()
        applyAppearance()
        resetPetPosition()
        showPet()

        if let launchError {
            throw launchError
        }
    }

    private func observeExecutionState() {
        executor.$state
            .sink { [weak self] state in
                guard let self else { return }
                feedbackResetTask?.cancel()
                switch state {
                case .idle:
                    if timer.snapshot.status != .running {
                        companionStateMachine.transition(to: .idle)
                    }
                case .running:
                    companionStateMachine.transition(to: .working)
                case .succeeded:
                    companionStateMachine.transition(to: .success)
                    schedulePetStateReset()
                case .failed:
                    companionStateMachine.transition(to: .error)
                    schedulePetStateReset()
                }
                publishCompanionState()
            }
            .store(in: &cancellables)
    }

    private func observeTimerState() {
        timer.$snapshot
            .removeDuplicates()
            .sink { [weak self] snapshot in
                guard let self else { return }
                if case .running = executor.state { return }
                switch snapshot.status {
                case .running:
                    if petState == .idle || petState == .curious || petState == .waiting {
                        companionStateMachine.transition(to: .waiting)
                    }
                case .completed:
                    companionStateMachine.transition(to: .success)
                    schedulePetStateReset()
                case .idle, .cancelled:
                    if petState == .waiting {
                        companionStateMachine.transition(to: .idle)
                    }
                }
                publishCompanionState()
            }
            .store(in: &cancellables)
    }

    private func schedulePetStateReset() {
        feedbackResetTask = Task { [weak self] in
            guard let self else { return }
            let duration = settings.value.personality.parameters.reactionDuration
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            companionStateMachine.resetTemporaryFeedback(timerIsRunning: timer.snapshot.status == .running)
            publishCompanionState()
            executor.resetFeedback()
        }
    }

    private func publishCompanionState() {
        petState = companionStateMachine.state
    }
}
