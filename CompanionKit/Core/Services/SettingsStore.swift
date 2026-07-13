import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let storageKey = "companionKit.settings.v1"

    @Published private(set) var value: CompanionSettings

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder = JSONEncoder()
        decoder = JSONDecoder()

        if let data = defaults.data(forKey: Self.storageKey),
           let settings = try? decoder.decode(CompanionSettings.self, from: data) {
            value = settings
        } else {
            value = .defaults
        }
    }

    func update(_ mutation: (inout CompanionSettings) -> Void) {
        var updated = value
        mutation(&updated)
        value = updated
        persist()
    }

    func reset(preservingOnboarding: Bool = true) {
        let completed = value.onboardingCompleted
        value = .defaults
        if preservingOnboarding {
            value.onboardingCompleted = completed
        }
        persist()
    }

    private func persist() {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
