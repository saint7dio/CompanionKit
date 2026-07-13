import AppKit
import CoreAudio
import Foundation
import ServiceManagement
import UserNotifications

@MainActor
final class LiveWorkspaceService: WorkspaceServing {
    private let workspace: NSWorkspace
    private let fileManager: FileManager

    init(workspace: NSWorkspace = .shared, fileManager: FileManager = .default) {
        self.workspace = workspace
        self.fileManager = fileManager
    }

    func openFinder() async throws {
        try await openApplication(at: "/System/Library/CoreServices/Finder.app")
    }

    func openDownloads() async throws {
        try openDirectory(.downloadsDirectory, domain: .userDomainMask, name: "Downloads")
    }

    func openDocuments() async throws {
        try openDirectory(.documentDirectory, domain: .userDomainMask, name: "Documents")
    }

    func openDesktop() async throws {
        try openDirectory(.desktopDirectory, domain: .userDomainMask, name: "Desktop")
    }

    func openApplications() async throws {
        try openDirectory(.applicationDirectory, domain: .localDomainMask, name: "Applications")
    }

    private func openDirectory(
        _ directory: FileManager.SearchPathDirectory,
        domain: FileManager.SearchPathDomainMask,
        name: String
    ) throws {
        guard let url = fileManager.urls(for: directory, in: domain).first else {
            throw CompanionError.capabilityUnavailable("The \(name) folder could not be located.")
        }
        guard workspace.open(url) else {
            throw CompanionError.systemAPIFailure("Finder did not open the \(name) folder.")
        }
    }

    func openSystemSettings() async throws {
        if let url = workspace.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") {
            try await openApplication(at: url.path)
            return
        }
        try await openApplication(at: "/System/Applications/System Settings.app")
    }

    func openApplication(at path: String) async throws {
        let url = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: path) else {
            throw CompanionError.applicationNotFound(url.lastPathComponent)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            workspace.openApplication(at: url, configuration: .init()) { _, error in
                if let error {
                    continuation.resume(throwing: CompanionError.systemAPIFailure(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func hideOtherApplications() async throws {
        NSApplication.shared.hideOtherApplications(nil)
    }
}

@MainActor
final class LiveScreenshotService: ScreenshotServing {
    private let workspace: NSWorkspace
    private let fileManager: FileManager

    init(workspace: NSWorkspace = .shared, fileManager: FileManager = .default) {
        self.workspace = workspace
        self.fileManager = fileManager
    }

    func openScreenshotInterface() async throws {
        let path = "/System/Applications/Utilities/Screenshot.app"
        guard fileManager.fileExists(atPath: path) else {
            throw CompanionError.capabilityUnavailable("The macOS Screenshot app is unavailable.")
        }

        let url = URL(fileURLWithPath: path)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            workspace.openApplication(at: url, configuration: .init()) { _, error in
                if let error {
                    continuation.resume(throwing: CompanionError.systemAPIFailure(error.localizedDescription))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

@MainActor
final class LiveClipboardService: ClipboardServing {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func copy(_ text: String) throws {
        guard !text.isEmpty else {
            throw CompanionError.invalidConfiguration("The saved text snippet is empty.")
        }
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw CompanionError.systemAPIFailure("The text could not be copied to the clipboard.")
        }
    }
}

@MainActor
final class CoreAudioService: AudioServing {
    private let step: Float = 0.0625
    private var volumeBeforeFallbackMute: Float = 0.5

    func isAvailable() -> Bool {
        (try? currentVolume()) != nil
    }

    func increaseVolume() throws -> Float {
        let wasMuted = try currentMuted()
        let updated = min(1, try currentVolume() + step)
        try setVolume(updated)
        if wasMuted {
            try setMuted(false)
        }
        return updated
    }

    func decreaseVolume() throws -> Float {
        let updated = max(0, try currentVolume() - step)
        try setVolume(updated)
        return updated
    }

    func toggleMute() throws -> Bool {
        let muted = try currentMuted()
        try setMuted(!muted)
        return !muted
    }

    private func outputDevice() throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &device
        )
        guard status == noErr, device != 0 else {
            throw CompanionError.capabilityUnavailable("No controllable audio output is available.")
        }
        return device
    }

    private func currentVolume() throws -> Float {
        let device = try outputDevice()
        var address = volumeAddress
        guard AudioObjectHasProperty(device, &address) else {
            throw CompanionError.capabilityUnavailable("This audio device does not expose volume control.")
        }
        var value: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        guard status == noErr else {
            throw CompanionError.systemAPIFailure("The current volume could not be read (\(status)).")
        }
        return value
    }

    private func setVolume(_ newValue: Float) throws {
        let device = try outputDevice()
        var address = volumeAddress
        guard isPropertySettable(device: device, address: &address) else {
            throw CompanionError.capabilityUnavailable("This audio device does not allow volume changes.")
        }
        var value = Float32(newValue)
        let size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectSetPropertyData(device, &address, 0, nil, size, &value)
        guard status == noErr else {
            throw CompanionError.systemAPIFailure("The volume could not be changed (\(status)).")
        }
    }

    private func currentMuted() throws -> Bool {
        let device = try outputDevice()
        var address = muteAddress
        guard AudioObjectHasProperty(device, &address) else {
            return try currentVolume() == 0
        }
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        guard status == noErr else {
            throw CompanionError.systemAPIFailure("The mute state could not be read (\(status)).")
        }
        return value != 0
    }

    private func setMuted(_ muted: Bool) throws {
        let device = try outputDevice()
        var address = muteAddress
        guard AudioObjectHasProperty(device, &address),
              isPropertySettable(device: device, address: &address) else {
            if muted {
                let volume = try currentVolume()
                if volume > 0 {
                    volumeBeforeFallbackMute = volume
                }
                try setVolume(0)
                return
            }
            try setVolume(max(volumeBeforeFallbackMute, step))
            return
        }
        var value: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectSetPropertyData(device, &address, 0, nil, size, &value)
        guard status == noErr else {
            throw CompanionError.systemAPIFailure("Mute could not be changed (\(status)).")
        }
    }

    private var volumeAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    private var muteAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
    }

    private func isPropertySettable(
        device: AudioDeviceID,
        address: inout AudioObjectPropertyAddress
    ) -> Bool {
        var settable = DarwinBoolean(false)
        let status = AudioObjectIsPropertySettable(device, &address, &settable)
        return status == noErr && settable.boolValue
    }
}

final class LocalNotificationService: NSObject, NotificationServing, UNUserNotificationCenterDelegate {
    static let timerIdentifier = "companionkit.timer"
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    func scheduleTimerNotification(identifier: String, at date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "CompanionKit timer finished"
        content.body = "Your countdown is complete."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            throw CompanionError.systemAPIFailure("The timer notification could not be scheduled.")
        }
    }

    func cancel(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@MainActor
final class LaunchAtLoginService: LaunchAtLoginServing {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    var hasRegistration: Bool { SMAppService.mainApp.status != .notRegistered }

    func setEnabled(_ enabled: Bool) throws {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval {
                    throw CompanionError.permissionDenied(
                        "Approve CompanionKit in System Settings > General > Login Items."
                    )
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch let error as CompanionError {
            throw error
        } catch {
            throw CompanionError.systemAPIFailure(
                "Launch at login could not be changed. It may require approval in System Settings."
            )
        }
    }
}
