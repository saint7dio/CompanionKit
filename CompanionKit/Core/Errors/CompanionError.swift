import Foundation

enum CompanionError: Error, Equatable, LocalizedError, Sendable {
    case permissionDenied(String)
    case capabilityUnavailable(String)
    case applicationNotFound(String)
    case systemAPIFailure(String)
    case invalidConfiguration(String)
    case operationCancelled
    case unsupportedSystemVersion(String)
    case unexpected(String)

    var errorDescription: String? {
        switch self {
        case let .permissionDenied(message):
            "Permission denied: \(message)"
        case let .capabilityUnavailable(message):
            "Unavailable: \(message)"
        case let .applicationNotFound(message):
            "Application not found: \(message)"
        case let .systemAPIFailure(message):
            "The Mac could not complete that action: \(message)"
        case let .invalidConfiguration(message):
            "Check CompanionKit settings: \(message)"
        case .operationCancelled:
            "The action was cancelled."
        case let .unsupportedSystemVersion(message):
            "This macOS version is unsupported: \(message)"
        case let .unexpected(message):
            "Something unexpected happened: \(message)"
        }
    }

    static func userFacing(_ error: Error) -> CompanionError {
        if let companionError = error as? CompanionError {
            return companionError
        }
        return .unexpected(error.localizedDescription)
    }
}
