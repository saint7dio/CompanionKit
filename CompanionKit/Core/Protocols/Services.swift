import AppKit
import Foundation

@MainActor
protocol WorkspaceServing: AnyObject {
    func openFinder() async throws
    func openDownloads() async throws
    func openDocuments() async throws
    func openDesktop() async throws
    func openApplications() async throws
    func openSystemSettings() async throws
    func openApplication(at path: String) async throws
    func hideOtherApplications() async throws
}

@MainActor
protocol ScreenshotServing: AnyObject {
    func openScreenshotInterface() async throws
}

@MainActor
protocol AudioServing: AnyObject {
    func increaseVolume() throws -> Float
    func decreaseVolume() throws -> Float
    func toggleMute() throws -> Bool
    func isAvailable() -> Bool
}

@MainActor
protocol ClipboardServing: AnyObject {
    func copy(_ text: String) throws
}

@MainActor
protocol NotificationServing: AnyObject {
    func requestAuthorizationIfNeeded() async -> Bool
    func scheduleTimerNotification(identifier: String, at date: Date) async throws
    func cancel(identifier: String)
}

@MainActor
protocol LaunchAtLoginServing: AnyObject {
    var isEnabled: Bool { get }
    var hasRegistration: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}
