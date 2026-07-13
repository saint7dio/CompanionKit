import Foundation
import Testing
@testable import CompanionKit

@Suite("Countdown timer controller")
@MainActor
struct CountdownTimerControllerTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func notificationDenialLeavesTimerRunningWithoutScheduling() async {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        let settings = SettingsStore(defaults: storage.defaults)
        let notifications = NotificationServiceSpy()
        notifications.authorizationResult = false
        let controller = CountdownTimerController(
            settings: settings,
            notifications: notifications,
            now: { now }
        )

        await controller.start(duration: 120)

        #expect(controller.snapshot.status == .running)
        #expect(controller.snapshot.endDate == now.addingTimeInterval(120))
        #expect(settings.value.activeTimerEndDate == now.addingTimeInterval(120))
        #expect(notifications.requestAuthorizationCallCount == 1)
        #expect(notifications.scheduledIdentifiers.isEmpty)
        #expect(
            controller.notificationWarning
                == "Notifications are off. The timer will still run while CompanionKit is open."
        )
    }

    @Test
    func authorizedStartSchedulesNotificationAtTimerEnd() async {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        let settings = SettingsStore(defaults: storage.defaults)
        let notifications = NotificationServiceSpy()
        let controller = CountdownTimerController(
            settings: settings,
            notifications: notifications,
            now: { now }
        )

        await controller.start(duration: 75)

        #expect(controller.snapshot.status == .running)
        #expect(controller.notificationWarning == nil)
        #expect(notifications.requestAuthorizationCallCount == 1)
        #expect(notifications.scheduledIdentifiers == [LocalNotificationService.timerIdentifier])
        #expect(notifications.scheduledDates == [now.addingTimeInterval(75)])
    }

    @Test
    func cancelClearsPersistenceAndPendingNotification() async {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        let settings = SettingsStore(defaults: storage.defaults)
        let notifications = NotificationServiceSpy()
        let controller = CountdownTimerController(
            settings: settings,
            notifications: notifications,
            now: { now }
        )
        await controller.start(duration: 60)

        controller.cancel()

        #expect(
            controller.snapshot
                == CountdownSnapshot(status: .cancelled, endDate: nil, remaining: 0)
        )
        #expect(settings.value.activeTimerEndDate == nil)
        #expect(notifications.cancelledIdentifiers == [LocalNotificationService.timerIdentifier])
        #expect(SettingsStore(defaults: storage.defaults).value.activeTimerEndDate == nil)
    }

    @Test
    func initializationRestoresFutureTimerWithoutRequestingNotificationPermission() {
        let storage = IsolatedUserDefaults()
        defer { storage.cleanUp() }
        let settings = SettingsStore(defaults: storage.defaults)
        let endDate = now.addingTimeInterval(240)
        settings.update { $0.activeTimerEndDate = endDate }
        let notifications = NotificationServiceSpy()

        let controller = CountdownTimerController(
            settings: settings,
            notifications: notifications,
            now: { now }
        )

        #expect(
            controller.snapshot
                == CountdownSnapshot(status: .running, endDate: endDate, remaining: 240)
        )
        #expect(notifications.requestAuthorizationCallCount == 0)
        #expect(notifications.scheduledIdentifiers.isEmpty)
        #expect(settings.value.activeTimerEndDate == endDate)
    }
}
