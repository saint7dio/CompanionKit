import Foundation

@MainActor
final class BuiltInAction: CompanionAction {
    let id: String
    let title: String
    let description: String
    let systemImageName: String
    let category: ActionCategory
    let riskLevel: ActionRiskLevel
    let requiredCapabilities: Set<ActionCapability>
    let requiresConfirmation: Bool

    private let availabilityHandler: @MainActor (ActionContext) async -> ActionAvailability
    private let executionHandler: @MainActor (ActionContext) async throws -> ActionResult

    init(
        id: String,
        title: String,
        description: String,
        systemImageName: String,
        category: ActionCategory,
        riskLevel: ActionRiskLevel = .low,
        requiredCapabilities: Set<ActionCapability>,
        requiresConfirmation: Bool = false,
        availability: @escaping @MainActor (ActionContext) async -> ActionAvailability = { _ in .available },
        execute: @escaping @MainActor (ActionContext) async throws -> ActionResult
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.systemImageName = systemImageName
        self.category = category
        self.riskLevel = riskLevel
        self.requiredCapabilities = requiredCapabilities
        self.requiresConfirmation = requiresConfirmation
        availabilityHandler = availability
        executionHandler = execute
    }

    func availability(in context: ActionContext) async -> ActionAvailability {
        await availabilityHandler(context)
    }

    func execute(context: ActionContext) async throws -> ActionResult {
        try await executionHandler(context)
    }
}

@MainActor
enum BuiltInActionFactory {
    static func makeActions() -> [any CompanionAction] {
        [
            BuiltInAction(
                id: "open-finder",
                title: "Open Finder",
                description: "Open a new Finder window.",
                systemImageName: "folder",
                category: .places,
                requiredCapabilities: [.applicationLaunching]
            ) { context in
                try await context.workspace.openFinder()
                return .success("Finder opened", message: "Finder is ready.")
            },
            BuiltInAction(
                id: "open-downloads",
                title: "Open Downloads",
                description: "Show your Downloads folder in Finder.",
                systemImageName: "arrow.down.circle",
                category: .places,
                requiredCapabilities: [.fileSystemLocations]
            ) { context in
                try await context.workspace.openDownloads()
                return .success("Downloads opened", message: "Your Downloads folder is open.")
            },
            BuiltInAction(
                id: "open-documents",
                title: "Open Documents",
                description: "Show your Documents folder in Finder.",
                systemImageName: "doc",
                category: .places,
                requiredCapabilities: [.fileSystemLocations]
            ) { context in
                try await context.workspace.openDocuments()
                return .success("Documents opened", message: "Your Documents folder is open.")
            },
            BuiltInAction(
                id: "open-desktop",
                title: "Open Desktop",
                description: "Show your Desktop folder in Finder.",
                systemImageName: "macwindow",
                category: .places,
                requiredCapabilities: [.fileSystemLocations]
            ) { context in
                try await context.workspace.openDesktop()
                return .success("Desktop opened", message: "Your Desktop folder is open.")
            },
            BuiltInAction(
                id: "open-applications",
                title: "Open Applications",
                description: "Show installed applications in Finder.",
                systemImageName: "square.grid.2x2",
                category: .places,
                requiredCapabilities: [.fileSystemLocations]
            ) { context in
                try await context.workspace.openApplications()
                return .success("Applications opened", message: "The Applications folder is open.")
            },
            BuiltInAction(
                id: "open-preferred-app",
                title: "Open Favorite App",
                description: "Launch the application selected in Settings.",
                systemImageName: "app.badge",
                category: .productivity,
                requiredCapabilities: [.applicationLaunching],
                availability: { context in
                    guard let path = context.settings.value.preferredApplicationPath, !path.isEmpty else {
                        return .unavailable(reason: "Choose a favorite application in Settings first.")
                    }
                    return isValidApplication(at: path)
                        ? .available
                        : .unavailable(reason: "The selected item is no longer a valid application.")
                }
            ) { context in
                guard let path = context.settings.value.preferredApplicationPath else {
                    throw CompanionError.invalidConfiguration("Choose a favorite application first.")
                }
                guard isValidApplication(at: path) else {
                    throw CompanionError.applicationNotFound("The selected item is no longer a valid application.")
                }
                let resolvedPath = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
                try await context.workspace.openApplication(at: resolvedPath)
                return .success(
                    "Application opened",
                    message: URL(fileURLWithPath: resolvedPath).deletingPathExtension().lastPathComponent
                )
            },
            BuiltInAction(
                id: "screenshot",
                title: "Take a Screenshot",
                description: "Open the standard macOS screenshot controls.",
                systemImageName: "camera.viewfinder",
                category: .productivity,
                riskLevel: .medium,
                requiredCapabilities: [.screenshotInterface]
            ) { context in
                try await context.screenshot.openScreenshotInterface()
                return .success("Screenshot controls opened", message: "Choose what you want to capture.")
            },
            volumeAction(id: "volume-up", title: "Volume Up", icon: "speaker.plus", direction: .up),
            volumeAction(id: "volume-down", title: "Volume Down", icon: "speaker.minus", direction: .down),
            BuiltInAction(
                id: "toggle-mute",
                title: "Mute or Unmute",
                description: "Toggle the default sound output.",
                systemImageName: "speaker.slash",
                category: .system,
                requiredCapabilities: [.systemAudio],
                availability: audioAvailability
            ) { context in
                let muted = try context.audio.toggleMute()
                return .success(
                    muted ? "Sound muted" : "Sound unmuted",
                    message: muted ? "Audio is muted." : "Audio is on."
                )
            },
            BuiltInAction(
                id: "date-time",
                title: "Date and Time",
                description: "Show the current local date and time.",
                systemImageName: "calendar.badge.clock",
                category: .productivity,
                requiredCapabilities: []
            ) { _ in
                .success(
                    "Date and time",
                    message: Date.now.formatted(date: .long, time: .shortened)
                )
            },
            BuiltInAction(
                id: "copy-snippet",
                title: "Copy Saved Text",
                description: "Copy your configured text snippet.",
                systemImageName: "doc.on.clipboard",
                category: .productivity,
                requiredCapabilities: [.clipboard],
                availability: { context in
                    context.settings.value.clipboardSnippet
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                        ? .unavailable(reason: "Add a text snippet in Settings first.")
                        : .available
                }
            ) { context in
                try context.clipboard.copy(context.settings.value.clipboardSnippet)
                return .success("Text copied", message: "Your saved text is on the clipboard.")
            },
            BuiltInAction(
                id: "hide-other-apps",
                title: "Hide Other Apps",
                description: "Hide other applications to reduce visual clutter.",
                systemImageName: "rectangle.on.rectangle.slash",
                category: .system,
                riskLevel: .medium,
                requiredCapabilities: [.applicationManagement],
                requiresConfirmation: true
            ) { context in
                try await context.workspace.hideOtherApplications()
                return .success("Other apps hidden", message: "Use the Dock to bring an app back.")
            },
            BuiltInAction(
                id: "system-settings",
                title: "Open System Settings",
                description: "Open macOS System Settings.",
                systemImageName: "gearshape",
                category: .system,
                requiredCapabilities: [.applicationLaunching]
            ) { context in
                try await context.workspace.openSystemSettings()
                return .success("System Settings opened", message: "System Settings is ready.")
            }
        ]
    }

    private enum VolumeDirection { case up, down }

    private static func volumeAction(
        id: String,
        title: String,
        icon: String,
        direction: VolumeDirection
    ) -> any CompanionAction {
        BuiltInAction(
            id: id,
            title: title,
            description: direction == .up
                ? "Increase the default output volume."
                : "Decrease the default output volume.",
            systemImageName: icon,
            category: .system,
            requiredCapabilities: [.systemAudio],
            availability: audioAvailability
        ) { context in
            let volume = try direction == .up
                ? context.audio.increaseVolume()
                : context.audio.decreaseVolume()
            return .success(title, message: "Volume is \(Int((volume * 100).rounded())) percent.")
        }
    }

    private static let audioAvailability: @MainActor (ActionContext) async -> ActionAvailability = { context in
        context.audio.isAvailable()
            ? .available
            : .unavailable(reason: "The current audio output does not support volume control.")
    }

    private static func isValidApplication(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              url.pathExtension.lowercased() == "app" else {
            return false
        }
        return Bundle(url: url)?.bundleIdentifier != nil
    }
}
