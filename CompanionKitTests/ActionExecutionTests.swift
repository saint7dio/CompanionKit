import Foundation
import Testing
@testable import CompanionKit

@Suite("Action registry and execution")
@MainActor
struct ActionExecutionTests {
    @Test
    func testRegistryKeepsFirstDuplicateAndFiltersByCategory() {
        let first = StubAction(id: "duplicate", title: "First", category: .places)
        let duplicate = StubAction(id: "duplicate", title: "Second", category: .system)
        let productivity = StubAction(id: "productivity", category: .productivity)

        let registry = ActionRegistry(actions: [first, duplicate, productivity])

        #expect(registry.actions.map { $0.id } == ["duplicate", "productivity"])
        #expect(registry.action(id: "duplicate")?.title == "First")
        #expect(registry.actions(in: .places).map { $0.id } == ["duplicate"])
        #expect(registry.actions(in: .system).isEmpty)
        #expect(registry.action(id: "missing") == nil)
    }

    @Test
    func testExecutorRunsAvailableBuiltInActionAndPublishesSuccess() async throws {
        let harness = ActionTestHarness()
        defer { harness.cleanUp() }
        let executor = ActionExecutor(context: harness.context)
        let registry = ActionRegistry(actions: BuiltInActionFactory.makeActions())
        let action = try #require(registry.action(id: "open-finder"))

        let result = await executor.execute(action)

        let expected = ActionResult.success("Finder opened", message: "Finder is ready.")
        #expect(result == expected)
        #expect(executor.state == .succeeded(expected))
        #expect(harness.workspace.openFinderCallCount == 1)

        executor.resetFeedback()
        #expect(executor.state == .idle)
    }

    @Test
    func testUnavailableActionDoesNotExecuteAndExplainsWhy() async {
        let harness = ActionTestHarness()
        defer { harness.cleanUp() }
        let action = StubAction(
            id: "offline",
            title: "Offline Action",
            availability: .unavailable(reason: "The required service is offline.")
        )
        let executor = ActionExecutor(context: harness.context)

        let availability = await executor.availability(of: action)
        let result = await executor.execute(action)

        #expect(availability == .unavailable(reason: "The required service is offline."))
        #expect(result == nil)
        #expect(action.executeCallCount == 0)
        #expect(
            executor.state == .failed(
                title: "Offline Action",
                message: "The required service is offline."
            )
        )
    }

    @Test
    func testBuiltInAudioAvailabilityUsesInjectedService() async throws {
        let harness = ActionTestHarness()
        defer { harness.cleanUp() }
        harness.audio.available = false
        let registry = ActionRegistry(actions: BuiltInActionFactory.makeActions())
        let action = try #require(registry.action(id: "volume-up"))
        let executor = ActionExecutor(context: harness.context)

        let result = await executor.execute(action)

        #expect(result == nil)
        #expect(harness.audio.increaseCallCount == 0)
        #expect(
            executor.state == .failed(
                title: "Volume Up",
                message: "The current audio output does not support volume control."
            )
        )
    }

    @Test
    func testConfirmationPreventsSideEffectUntilConfirmed() async throws {
        let harness = ActionTestHarness()
        defer { harness.cleanUp() }
        let registry = ActionRegistry(actions: BuiltInActionFactory.makeActions())
        let action = try #require(registry.action(id: "hide-other-apps"))
        let executor = ActionExecutor(context: harness.context)

        let unconfirmedResult = await executor.execute(action)

        #expect(unconfirmedResult == nil)
        #expect(harness.workspace.hideOtherApplicationsCallCount == 0)
        #expect(
            executor.state == .failed(
                title: "Hide Other Apps",
                message: "Confirmation is required before this action runs."
            )
        )

        let confirmedResult = await executor.execute(action, confirmed: true)

        #expect(
            confirmedResult == ActionResult.success(
                "Other apps hidden",
                message: "Use the Dock to bring an app back."
            )
        )
        #expect(harness.workspace.hideOtherApplicationsCallCount == 1)
    }

    @Test
    func testConfirmationPolicyRequiresConfirmationForHighRiskActions() {
        let highRisk = StubAction(id: "high-risk", riskLevel: .high)
        let explicit = StubAction(id: "explicit", requiresConfirmation: true)
        let lowRisk = StubAction(id: "low-risk")
        let policy = ActionConfirmationPolicy()

        let highRiskRequiresConfirmation = policy.requiresConfirmation(for: highRisk)
        let explicitRequiresConfirmation = policy.requiresConfirmation(for: explicit)
        let lowRiskRequiresConfirmation = policy.requiresConfirmation(for: lowRisk)

        #expect(highRiskRequiresConfirmation)
        #expect(explicitRequiresConfirmation)
        #expect(!lowRiskRequiresConfirmation)
    }

    @Test
    func testPermissionErrorFromInjectedServiceBecomesUserFacingFailure() async throws {
        let harness = ActionTestHarness()
        defer { harness.cleanUp() }
        harness.workspace.openFinderError = CompanionError.permissionDenied(
            "Allow Finder access in System Settings."
        )
        let registry = ActionRegistry(actions: BuiltInActionFactory.makeActions())
        let action = try #require(registry.action(id: "open-finder"))
        let executor = ActionExecutor(context: harness.context)

        let result = await executor.execute(action)

        #expect(result == nil)
        #expect(harness.workspace.openFinderCallCount == 1)
        #expect(
            executor.state == .failed(
                title: "Open Finder",
                message: "Permission denied: Allow Finder access in System Settings."
            )
        )
    }

    @Test
    func testUnexpectedErrorIsMappedWithoutLosingItsDescription() async {
        let harness = ActionTestHarness()
        defer { harness.cleanUp() }
        let underlying = NSError(
            domain: "CompanionKitTests",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "The test service disconnected."]
        )
        let action = StubAction(id: "failing", title: "Failing Action") { _ in
            throw underlying
        }
        let executor = ActionExecutor(context: harness.context)

        let result = await executor.execute(action)

        #expect(result == nil)
        #expect(
            CompanionError.userFacing(underlying)
                == .unexpected("The test service disconnected.")
        )
        #expect(
            executor.state == .failed(
                title: "Failing Action",
                message: "Something unexpected happened: The test service disconnected."
            )
        )
    }
}
