import Combine
import Foundation

enum CountdownStatus: Equatable, Sendable {
    case idle
    case running
    case completed
    case cancelled
}

struct CountdownSnapshot: Equatable, Sendable {
    var status: CountdownStatus = .idle
    var endDate: Date?
    var remaining: TimeInterval = 0

    var formattedRemaining: String {
        let total = max(0, Int(remaining.rounded(.up)))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}

struct CountdownStateMachine: Sendable {
    private(set) var snapshot = CountdownSnapshot()

    mutating func start(duration: TimeInterval, now: Date) throws {
        guard duration > 0 else {
            throw CompanionError.invalidConfiguration("Timer duration must be greater than zero.")
        }
        let endDate = now.addingTimeInterval(duration)
        snapshot = CountdownSnapshot(status: .running, endDate: endDate, remaining: duration)
    }

    mutating func restore(endDate: Date, now: Date) {
        let remaining = endDate.timeIntervalSince(now)
        snapshot = remaining > 0
            ? CountdownSnapshot(status: .running, endDate: endDate, remaining: remaining)
            : CountdownSnapshot(status: .completed, endDate: nil, remaining: 0)
    }

    @discardableResult
    mutating func refresh(now: Date) -> Bool {
        guard snapshot.status == .running, let endDate = snapshot.endDate else { return false }
        let remaining = endDate.timeIntervalSince(now)
        if remaining <= 0 {
            snapshot = CountdownSnapshot(status: .completed, endDate: nil, remaining: 0)
            return true
        }
        snapshot.remaining = remaining
        return false
    }

    mutating func cancel() {
        snapshot = CountdownSnapshot(status: .cancelled, endDate: nil, remaining: 0)
    }

    mutating func reset() {
        snapshot = CountdownSnapshot()
    }
}

@MainActor
final class CountdownTimerController: ObservableObject {
    @Published private(set) var snapshot = CountdownSnapshot()
    @Published private(set) var notificationWarning: String?

    private var machine = CountdownStateMachine()
    private var tickerTask: Task<Void, Never>?
    private let settings: SettingsStore
    private let notifications: any NotificationServing
    private let now: () -> Date

    init(
        settings: SettingsStore,
        notifications: any NotificationServing,
        now: @escaping () -> Date = Date.init
    ) {
        self.settings = settings
        self.notifications = notifications
        self.now = now
        restoreIfNeeded()
    }

    deinit {
        tickerTask?.cancel()
    }

    func start(minutes: Int) async {
        await start(duration: TimeInterval(minutes * 60))
    }

    func start(duration: TimeInterval) async {
        do {
            try machine.start(duration: duration, now: now())
        } catch {
            notificationWarning = CompanionError.userFacing(error).localizedDescription
            return
        }

        snapshot = machine.snapshot
        notificationWarning = nil
        settings.update { $0.activeTimerEndDate = snapshot.endDate }
        beginTicking()

        guard let endDate = snapshot.endDate else { return }
        let authorized = await notifications.requestAuthorizationIfNeeded()
        guard authorized else {
            notificationWarning = "Notifications are off. The timer will still run while CompanionKit is open."
            return
        }
        do {
            try await notifications.scheduleTimerNotification(
                identifier: LocalNotificationService.timerIdentifier,
                at: endDate
            )
        } catch {
            notificationWarning = CompanionError.userFacing(error).localizedDescription
        }
    }

    func cancel() {
        tickerTask?.cancel()
        tickerTask = nil
        machine.cancel()
        snapshot = machine.snapshot
        settings.update { $0.activeTimerEndDate = nil }
        notifications.cancel(identifier: LocalNotificationService.timerIdentifier)
    }

    func reset() {
        machine.reset()
        snapshot = machine.snapshot
        notificationWarning = nil
    }

    func refresh() {
        let completed = machine.refresh(now: now())
        snapshot = machine.snapshot
        if completed {
            tickerTask?.cancel()
            tickerTask = nil
            settings.update { $0.activeTimerEndDate = nil }
        }
    }

    private func restoreIfNeeded() {
        guard let endDate = settings.value.activeTimerEndDate else { return }
        machine.restore(endDate: endDate, now: now())
        snapshot = machine.snapshot
        if snapshot.status == .running {
            beginTicking()
        } else {
            settings.update { $0.activeTimerEndDate = nil }
        }
    }

    private func beginTicking() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                self?.refresh()
                if self?.snapshot.status != .running { return }
            }
        }
    }
}
