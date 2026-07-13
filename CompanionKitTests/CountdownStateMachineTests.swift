import Foundation
import Testing
@testable import CompanionKit

@Suite("Countdown state machine")
struct CountdownStateMachineTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func testStartCreatesRunningSnapshotWithExactEndDate() throws {
        var machine = CountdownStateMachine()

        try machine.start(duration: 90, now: now)

        #expect(machine.snapshot.status == .running)
        #expect(machine.snapshot.endDate == now.addingTimeInterval(90))
        #expect(machine.snapshot.remaining == 90)
        #expect(machine.snapshot.formattedRemaining == "01:30")
    }

    @Test
    func testStartRejectsNonPositiveDurationWithoutChangingState() {
        var machine = CountdownStateMachine()

        do {
            try machine.start(duration: 0, now: now)
            Issue.record("Expected a non-positive duration to be rejected")
        } catch let error as CompanionError {
            #expect(
                error == .invalidConfiguration("Timer duration must be greater than zero.")
            )
        } catch {
            Issue.record("Expected CompanionError, got \(error)")
        }
        #expect(machine.snapshot == CountdownSnapshot())
    }

    @Test
    func testRefreshUpdatesRemainingThenCompletesAtEndDate() throws {
        var machine = CountdownStateMachine()
        try machine.start(duration: 120, now: now)

        let completedEarly = machine.refresh(now: now.addingTimeInterval(35))

        #expect(!completedEarly)
        #expect(machine.snapshot.status == .running)
        #expect(machine.snapshot.remaining == 85)
        #expect(machine.snapshot.endDate == now.addingTimeInterval(120))

        let completedAtEnd = machine.refresh(now: now.addingTimeInterval(120))

        #expect(completedAtEnd)
        #expect(
            machine.snapshot
                == CountdownSnapshot(status: .completed, endDate: nil, remaining: 0)
        )
        let refreshedAfterCompletion = machine.refresh(now: now.addingTimeInterval(121))
        #expect(!refreshedAfterCompletion)
    }

    @Test
    func testCancelClearsAStartedTimer() throws {
        var machine = CountdownStateMachine()
        try machine.start(duration: 60, now: now)

        machine.cancel()

        #expect(
            machine.snapshot
                == CountdownSnapshot(status: .cancelled, endDate: nil, remaining: 0)
        )
        let refreshedAfterCancellation = machine.refresh(now: now.addingTimeInterval(10))
        #expect(!refreshedAfterCancellation)
    }

    @Test
    func testRestoreFutureEndDateResumesRunningTimer() {
        var machine = CountdownStateMachine()
        let endDate = now.addingTimeInterval(300)

        machine.restore(endDate: endDate, now: now)

        #expect(
            machine.snapshot
                == CountdownSnapshot(status: .running, endDate: endDate, remaining: 300)
        )
    }

    @Test
    func testRestoreExpiredEndDateCompletesTimer() {
        var machine = CountdownStateMachine()

        machine.restore(endDate: now.addingTimeInterval(-1), now: now)

        #expect(
            machine.snapshot
                == CountdownSnapshot(status: .completed, endDate: nil, remaining: 0)
        )
    }
}
