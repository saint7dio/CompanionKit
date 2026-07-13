import Foundation
import Testing
@testable import CompanionKit

@Suite("Companion state, theme, and personality")
struct CompanionStateAndThemeTests {
    @Test
    func defaultStateIsIdleAndHoverIsCurious() {
        var machine = CompanionStateMachine()

        #expect(machine.state == .idle)
        machine.setHovering(true)
        #expect(machine.state == .curious)
        machine.setHovering(false)
        #expect(machine.state == .idle)
    }

    @Test
    func hoverDoesNotInterruptHigherPriorityState() {
        var machine = CompanionStateMachine()
        machine.transition(to: .working)

        machine.setHovering(true)

        #expect(machine.state == .working)
    }

    @Test
    func hiddenStateRestoresPreviousVisibleState() {
        var machine = CompanionStateMachine()
        machine.transition(to: .waiting)

        machine.hide()
        #expect(machine.state == .hidden)
        machine.show()

        #expect(machine.state == .waiting)
    }

    @Test
    func temporaryFeedbackReturnsToTimerAwareState() {
        var machine = CompanionStateMachine()
        machine.transition(to: .success)
        machine.resetTemporaryFeedback(timerIsRunning: true)
        #expect(machine.state == .waiting)

        machine.transition(to: .error)
        machine.resetTemporaryFeedback(timerIsRunning: false)
        #expect(machine.state == .idle)
    }

    @Test
    func etherealIsTheOnlyMVPThemeAndIsWingless() throws {
        let theme = try #require(CompanionThemeRegistry.theme(id: .ethereal))

        #expect(CompanionThemeRegistry.themes.count == 1)
        #expect(theme.displayName == "Ethereal")
        #expect(theme.supportsParticles)
        #expect(theme.isWingless)
    }

    @Test
    func personalityParametersScaleWithoutChangingProductPolicy() {
        let calm = CompanionPersonalityPreset.calm.parameters
        let friendly = CompanionPersonalityPreset.friendly.parameters
        let energetic = CompanionPersonalityPreset.energetic.parameters

        #expect(calm.animationTempo < friendly.animationTempo)
        #expect(friendly.animationTempo < energetic.animationTempo)
        #expect(calm.movementAmplitude < energetic.movementAmplitude)
        #expect(calm.particleIntensity < energetic.particleIntensity)
        #expect(calm.reactionDuration > energetic.reactionDuration)
    }
}
