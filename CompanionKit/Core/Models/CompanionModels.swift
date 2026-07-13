import CoreGraphics
import Foundation

enum CompanionState: String, Codable, CaseIterable, Sendable {
    case idle
    case curious
    case thinking
    case working
    case success
    case error
    case sleeping
    case waiting
    case surprised
    case hidden

    var accessibilityDescription: String {
        switch self {
        case .idle: "Ready"
        case .curious: "Curious"
        case .thinking: "Thinking"
        case .working: "Working"
        case .success: "Action succeeded"
        case .error: "Action failed"
        case .sleeping: "Sleeping"
        case .waiting: "Waiting"
        case .surprised: "Surprised"
        case .hidden: "Hidden"
        }
    }
}

enum CompanionThemeID: String, Codable, CaseIterable, Identifiable, Sendable {
    case ethereal

    var id: String { rawValue }
    var displayName: String { "Ethereal" }
}

enum CompanionBaseColor: String, Codable, CaseIterable, Identifiable, Sendable {
    case iceBlue
    case moonViolet
    case mistMint
    case warmAmber
    case softRose
    case monochrome

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iceBlue: "Ice Blue"
        case .moonViolet: "Moon Violet"
        case .mistMint: "Mist Mint"
        case .warmAmber: "Warm Amber"
        case .softRose: "Soft Rose"
        case .monochrome: "Monochrome"
        }
    }
}

enum CompanionEffectIntensity: String, Codable, CaseIterable, Identifiable, Sendable {
    case off
    case subtle
    case standard

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var scale: Double {
        switch self {
        case .off: 0
        case .subtle: 0.55
        case .standard: 1
        }
    }
}

enum CompanionPersonalityPreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case calm
    case friendly
    case energetic

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var parameters: CompanionPersonality {
        switch self {
        case .calm:
            CompanionPersonality(animationTempo: 0.78, idleReactionFrequency: 0.45, movementAmplitude: 0.55, particleIntensity: 0.45, reactionDuration: 3.0)
        case .friendly:
            CompanionPersonality(animationTempo: 1.0, idleReactionFrequency: 0.7, movementAmplitude: 0.8, particleIntensity: 0.7, reactionDuration: 2.5)
        case .energetic:
            CompanionPersonality(animationTempo: 1.22, idleReactionFrequency: 0.95, movementAmplitude: 1.0, particleIntensity: 1.0, reactionDuration: 2.0)
        }
    }
}

struct CompanionPersonality: Equatable, Sendable {
    let animationTempo: Double
    let idleReactionFrequency: Double
    let movementAmplitude: Double
    let particleIntensity: Double
    let reactionDuration: TimeInterval
}

struct CompanionThemeDefinition: Equatable, Sendable {
    let id: CompanionThemeID
    let displayName: String
    let supportsParticles: Bool
    let isWingless: Bool
}

enum CompanionThemeRegistry {
    static let ethereal = CompanionThemeDefinition(
        id: .ethereal,
        displayName: "Ethereal",
        supportsParticles: true,
        isWingless: true
    )

    static let themes = [ethereal]

    static func theme(id: CompanionThemeID) -> CompanionThemeDefinition? {
        themes.first { $0.id == id }
    }
}

struct CompanionStateMachine: Equatable, Sendable {
    private(set) var state: CompanionState = .idle
    private(set) var previousVisibleState: CompanionState = .idle

    mutating func transition(to newState: CompanionState) {
        if newState != .hidden {
            previousVisibleState = newState
        }
        state = newState
    }

    mutating func setHovering(_ hovering: Bool) {
        guard state == .idle || state == .curious else { return }
        transition(to: hovering ? .curious : .idle)
    }

    mutating func hide() {
        if state != .hidden {
            previousVisibleState = state
        }
        state = .hidden
    }

    mutating func show() {
        state = previousVisibleState == .hidden ? .idle : previousVisibleState
    }

    mutating func resetTemporaryFeedback(timerIsRunning: Bool) {
        guard state == .success || state == .error || state == .surprised else { return }
        transition(to: timerIsRunning ? .waiting : .idle)
    }
}

enum ActionRiskLevel: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
}

enum ActionCapability: String, Codable, Hashable, Sendable {
    case applicationLaunching
    case fileSystemLocations
    case screenshotInterface
    case systemAudio
    case clipboard
    case applicationManagement
}

enum ActionAvailability: Equatable, Sendable {
    case available
    case unavailable(reason: String)

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    var unavailableReason: String? {
        if case let .unavailable(reason) = self { return reason }
        return nil
    }
}

struct ActionResult: Equatable, Sendable {
    let title: String
    let message: String

    static func success(_ title: String, message: String) -> ActionResult {
        ActionResult(title: title, message: message)
    }
}

struct StoredPoint: Codable, Equatable, Sendable {
    var x: Double
    var y: Double

    init(_ point: CGPoint) {
        x = point.x
        y = point.y
    }

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

enum PetSize: String, Codable, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var points: CGFloat {
        switch self {
        case .small: 96
        case .medium: 124
        case .large: 160
        }
    }
}

enum PreferredAppearance: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

struct CompanionSettings: Codable, Equatable, Sendable {
    static let canonicalCompanionName = "Veya"

    var petName = canonicalCompanionName
    var petSize = PetSize.medium
    var lastPetOrigin: StoredPoint?
    var animationEnabled = true
    var launchAtLogin = false
    var preferredApplicationPath: String?
    var preferredAppearance = PreferredAppearance.system
    var reducedInteractionMode = false
    var clipboardSnippet = "You’ve got this."
    var onboardingCompleted = false
    var petVisible = true
    var activeTimerEndDate: Date?
    var theme = CompanionThemeID.ethereal
    var baseColor = CompanionBaseColor.iceBlue
    var auraIntensity = CompanionEffectIntensity.standard
    var particleIntensity = CompanionEffectIntensity.subtle
    var personality = CompanionPersonalityPreset.friendly
    var reduceMotionOverride = false

    static let defaults = CompanionSettings()

    private enum CodingKeys: String, CodingKey {
        case petName, petSize, lastPetOrigin, animationEnabled, launchAtLogin
        case preferredApplicationPath, preferredAppearance, reducedInteractionMode
        case clipboardSnippet, onboardingCompleted, petVisible, activeTimerEndDate
        case theme, baseColor, auraIntensity, particleIntensity, personality
        case reduceMotionOverride
    }

    init() {}

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let decodedName = try values.decodeIfPresent(String.self, forKey: .petName)
            ?? Self.canonicalCompanionName
        petName = decodedName == "Pip" ? Self.canonicalCompanionName : decodedName
        petSize = try values.decodeIfPresent(PetSize.self, forKey: .petSize) ?? .medium
        lastPetOrigin = try values.decodeIfPresent(StoredPoint.self, forKey: .lastPetOrigin)
        animationEnabled = try values.decodeIfPresent(Bool.self, forKey: .animationEnabled) ?? true
        launchAtLogin = try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        preferredApplicationPath = try values.decodeIfPresent(String.self, forKey: .preferredApplicationPath)
        preferredAppearance = try values.decodeIfPresent(PreferredAppearance.self, forKey: .preferredAppearance) ?? .system
        reducedInteractionMode = try values.decodeIfPresent(Bool.self, forKey: .reducedInteractionMode) ?? false
        clipboardSnippet = try values.decodeIfPresent(String.self, forKey: .clipboardSnippet) ?? "You’ve got this."
        onboardingCompleted = try values.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        petVisible = try values.decodeIfPresent(Bool.self, forKey: .petVisible) ?? true
        activeTimerEndDate = try values.decodeIfPresent(Date.self, forKey: .activeTimerEndDate)
        theme = try values.decodeIfPresent(CompanionThemeID.self, forKey: .theme) ?? .ethereal
        baseColor = try values.decodeIfPresent(CompanionBaseColor.self, forKey: .baseColor) ?? .iceBlue
        auraIntensity = try values.decodeIfPresent(CompanionEffectIntensity.self, forKey: .auraIntensity) ?? .standard
        particleIntensity = try values.decodeIfPresent(CompanionEffectIntensity.self, forKey: .particleIntensity) ?? .subtle
        personality = try values.decodeIfPresent(CompanionPersonalityPreset.self, forKey: .personality) ?? .friendly
        reduceMotionOverride = try values.decodeIfPresent(Bool.self, forKey: .reduceMotionOverride) ?? false
    }
}
