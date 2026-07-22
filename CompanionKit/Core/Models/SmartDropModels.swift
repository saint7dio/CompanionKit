import Foundation

/// Smart Drop is intentionally either a local deterministic demonstration or
/// one explicitly confirmed OpenAI request. A drop alone never changes mode or
/// crosses a network boundary.
enum SmartDropMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case demo
    case live

    var id: String { rawValue }
}

enum SmartDropInputKind: String, Codable, CaseIterable, Sendable {
    case pdf
    case invoice
    case screenshot
    case image
    case text
}

/// Stable action identifiers form the complete semantic allowlist. Model text
/// can describe a result, but cannot invent an executable capability.
enum SmartDropActionID: String, Codable, CaseIterable, Hashable, Sendable {
    case summarize
    case extractFields
    case explain
    case rewrite
    case ocrInterpret
}

struct SmartDropInputDescriptor: Equatable, Sendable {
    let kind: SmartDropInputKind
    let displayName: String
    let byteCount: Int
    let pageCount: Int?
    let pixelWidth: Int?
    let pixelHeight: Int?
    let contentDigest: String
}

enum SmartDropPreparedContent: Equatable, Sendable {
    case text(String)
    case image(data: Data, mimeType: String, extractedText: String?)
    case pdf(data: Data, extractedText: String)
}

struct SmartDropPreparedInput: Equatable, Sendable {
    let descriptor: SmartDropInputDescriptor
    let content: SmartDropPreparedContent
}

struct SmartDropResultField: Codable, Equatable, Hashable, Sendable {
    let label: String
    let value: String
}

struct SmartDropPreparedResult: Codable, Equatable, Sendable {
    let text: String
    let fields: [SmartDropResultField]

    init(text: String, fields: [SmartDropResultField] = []) {
        self.text = text
        self.fields = fields
    }
}

struct SmartDropProposal: Codable, Equatable, Identifiable, Sendable {
    var id: SmartDropActionID { actionID }

    let actionID: SmartDropActionID
    let title: String
    let rationale: String
    let result: SmartDropPreparedResult
}

struct SmartDropAnalysisResult: Equatable, Sendable {
    let mode: SmartDropMode
    let model: String
    let proposals: [SmartDropProposal]
    let usage: SmartDropTokenUsage?

    init(
        mode: SmartDropMode,
        model: String,
        proposals: [SmartDropProposal],
        usage: SmartDropTokenUsage? = nil
    ) {
        self.mode = mode
        self.model = model
        self.proposals = proposals
        self.usage = usage
    }
}

/// Non-sensitive accounting metadata returned by the Responses API. It is
/// displayed locally for a confirmed request but is never persisted or logged.
struct SmartDropTokenUsage: Equatable, Sendable {
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    let reasoningTokens: Int

    init(
        inputTokens: Int,
        outputTokens: Int,
        totalTokens: Int,
        reasoningTokens: Int = 0
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
        self.reasoningTokens = reasoningTokens
    }
}

/// Consent is bound to the prepared bytes rather than only a filename. A file
/// replacement, mode change, or model change invalidates it before any request.
struct SmartDropConsent: Equatable, Sendable {
    let contentDigest: String
    let displayName: String
    let purpose: String
    let mode: SmartDropMode
    let model: String
    let responseLanguage: String
    let confirmedAt: Date

    func authorizes(
        _ input: SmartDropPreparedInput,
        purpose expectedPurpose: String,
        mode expectedMode: SmartDropMode,
        model expectedModel: String,
        responseLanguage expectedResponseLanguage: String
    ) -> Bool {
        contentDigest == input.descriptor.contentDigest
            && displayName == input.descriptor.displayName
            && purpose == expectedPurpose
            && mode == expectedMode
            && model == expectedModel
            && responseLanguage == expectedResponseLanguage
    }
}

struct SmartDropAnalysisRequest: Equatable, Sendable {
    let input: SmartDropPreparedInput
    let consent: SmartDropConsent
    let responseLanguage: String
}

enum OpenAICredentialStatus: Equatable, Sendable {
    case notConfigured
    case securelyStored
    /// Debug-only process environment source. The value remains outside the
    /// app's settings and Keychain and is never exposed through this status.
    case developmentEnvironment
}

enum SmartDropError: Error, Equatable, Sendable {
    case requiresSingleSupportedItem
    case unsupportedInput
    case inputMissing
    case inputUnreadable
    case inputTooLarge(maximumBytes: Int)
    case tooManyPDFPages(maximum: Int)
    case imagePreparationFailed
    case invalidConsent
    case missingCredential
    case liveModeUnavailable
    case invalidCredential
    case requestTimedOut
    case requestCancelled
    case serviceRejected(statusCode: Int)
    case invalidResponse
    case invalidProposalCount
    case duplicateActions
    case disallowedAction(SmartDropActionID)
    case resultTooLarge
    case credentialStorageFailed
    case resultCopyFailed
}

enum SmartDropConfiguration {
    /// Explicit project-verified GPT-5.6 target. Callers can still inject a
    /// different approved model into the live analyzer and controller.
    static let liveModel = "gpt-5.6-sol"
    static let demoModel = "CompanionKit Mock"
    static let analysisPurpose = "Propose exactly three contextual actions and prepare their results"
    static let maximumLiveOutputTokens = 1_200
    static let liveReasoningEffort = "none"
    static let supportedResponseLanguages: Set<String> = ["en", "de"]
    static let maximumTextBytes = 32 * 1_024
    static let maximumImageBytes = 5 * 1_024 * 1_024
    static let maximumImageDimension = 1_600
    static let maximumPDFBytes = 10 * 1_024 * 1_024
    static let maximumPDFPages = 10
}
