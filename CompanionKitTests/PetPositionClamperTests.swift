import CoreGraphics
import Testing
@testable import CompanionKit

@Suite("Pet position clamping")
struct PetPositionClamperTests {
    private let visibleFrame = CGRect(x: 100, y: 200, width: 500, height: 400)
    private let windowSize = CGSize(width: 120, height: 100)

    @Test
    func testOriginInsideVisibleFrameRemainsUnchanged() {
        let origin = CGPoint(x: 250, y: 350)

        #expect(
            PetPositionClamper.clamp(
                origin: origin,
                windowSize: windowSize,
                visibleFrame: visibleFrame
            ) == origin
        )
    }

    @Test
    func testOriginBelowMinimumEdgesClampsToVisibleFrameOrigin() {
        #expect(
            PetPositionClamper.clamp(
                origin: CGPoint(x: -500, y: -500),
                windowSize: windowSize,
                visibleFrame: visibleFrame
            ) == CGPoint(x: 100, y: 200)
        )
    }

    @Test
    func testOriginAboveMaximumEdgesKeepsEntireWindowVisible() {
        #expect(
            PetPositionClamper.clamp(
                origin: CGPoint(x: 1_000, y: 1_000),
                windowSize: windowSize,
                visibleFrame: visibleFrame
            ) == CGPoint(x: 480, y: 500)
        )
    }

    @Test
    func testExactBoundaryOriginsRemainUnchanged() {
        for origin in [CGPoint(x: 100, y: 200), CGPoint(x: 480, y: 500)] {
            #expect(
                PetPositionClamper.clamp(
                    origin: origin,
                    windowSize: windowSize,
                    visibleFrame: visibleFrame
                ) == origin
            )
        }
    }

    @Test
    func testWindowLargerThanVisibleFrameAnchorsAtMinimumEdges() {
        #expect(
            PetPositionClamper.clamp(
                origin: CGPoint(x: 350, y: 350),
                windowSize: CGSize(width: 700, height: 500),
                visibleFrame: visibleFrame
            ) == CGPoint(x: 100, y: 200)
        )
    }
}
