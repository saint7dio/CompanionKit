import Combine
import Foundation

struct SmartDropConsentPreview: Equatable, Sendable {
    let descriptor: SmartDropInputDescriptor
    let purpose: String
    let mode: SmartDropMode
    let model: String
    let responseLanguage: String

    var usesCloud: Bool { mode == .live }
    var mayCostMoney: Bool { mode == .live }
}

enum SmartDropPhase: Equatable, Sendable {
    case idle
    case preparing
    case consentRequired(SmartDropConsentPreview)
    case analyzing(SmartDropInputDescriptor)
    case proposals(SmartDropAnalysisResult)
    case executionConfirmation(SmartDropProposal, analysis: SmartDropAnalysisResult)
    case completed(SmartDropProposal, analysis: SmartDropAnalysisResult)
    case error(SmartDropError)
}

/// Owns the single-item Smart Drop transaction. Local preparation begins only
/// after the user requests suggestions; the analyzer begins only after consent;
/// selecting a proposal never causes another model request.
@MainActor
final class SmartDropController: ObservableObject {
    @Published private(set) var phase: SmartDropPhase = .idle
    @Published private(set) var requestCount = 0
    @Published private(set) var lastCopyError: SmartDropError?

    private let settings: SettingsStore
    private let preparer: any SmartDropInputPreparing
    private let demoAnalyzer: any SmartDropAnalyzing
    private let liveAnalyzer: any SmartDropAnalyzing
    private let credentialStatusProvider: any OpenAICredentialStatusProviding
    private let presenter: any FilePresentationServing
    private let validator: SmartDropResultValidator
    private let liveModeAvailable: Bool
    private let liveModel: String

    private var preparedInput: SmartDropPreparedInput?
    private var pendingPreview: SmartDropConsentPreview?
    private var workTask: Task<Void, Never>?
    private var transactionID = UUID()

    init(
        settings: SettingsStore,
        preparer: any SmartDropInputPreparing,
        demoAnalyzer: any SmartDropAnalyzing,
        liveAnalyzer: any SmartDropAnalyzing,
        credentialStore: any OpenAICredentialStore,
        credentialStatusProvider: (any OpenAICredentialStatusProviding)? = nil,
        presenter: any FilePresentationServing,
        liveModeAvailable: Bool = true,
        liveModel: String = SmartDropConfiguration.liveModel,
        validator: SmartDropResultValidator = SmartDropResultValidator()
    ) {
        self.settings = settings
        self.preparer = preparer
        self.demoAnalyzer = demoAnalyzer
        self.liveAnalyzer = liveAnalyzer
        self.credentialStatusProvider = credentialStatusProvider ?? credentialStore
        self.presenter = presenter
        self.liveModeAvailable = liveModeAvailable
        self.liveModel = liveModel
        self.validator = validator
    }

    deinit {
        workTask?.cancel()
    }

    var isBusy: Bool {
        if case .preparing = phase { return true }
        if case .analyzing = phase { return true }
        return false
    }

    func resetForNewDrop() {
        workTask?.cancel()
        workTask = nil
        transactionID = UUID()
        preparedInput = nil
        pendingPreview = nil
        lastCopyError = nil
        phase = .idle
    }

    func requestSuggestions(for classification: DropClassification) {
        guard !isBusy else { return }
        guard classification.items.count == 1,
              let item = classification.supportedItems.first else {
            phase = .error(.requiresSingleSupportedItem)
            return
        }

        resetForNewDrop()
        phase = .preparing
        let id = transactionID
        workTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let input = try await preparer.prepare(item)
                try Task.checkCancellation()
                guard transactionID == id else { return }
                let mode = settings.value.smartDropMode
                if mode == .live, !liveModeAvailable {
                    throw SmartDropError.liveModeUnavailable
                }
                if mode == .live, credentialStatusProvider.status() == .notConfigured {
                    throw SmartDropError.missingCredential
                }
                let preview = SmartDropConsentPreview(
                    descriptor: input.descriptor,
                    purpose: SmartDropConfiguration.analysisPurpose,
                    mode: mode,
                    model: mode == .live
                        ? liveModel
                        : SmartDropConfiguration.demoModel,
                    responseLanguage: settings.value.language.resolvedIdentifier
                )
                preparedInput = input
                pendingPreview = preview
                phase = .consentRequired(preview)
            } catch is CancellationError {
                guard transactionID == id else { return }
                phase = .idle
            } catch let error as SmartDropError {
                guard transactionID == id else { return }
                phase = .error(error)
            } catch {
                guard transactionID == id else { return }
                phase = .error(.inputUnreadable)
            }
            workTask = nil
        }
    }

    func confirmAnalysis() {
        guard case let .consentRequired(preview) = phase,
              preview == pendingPreview,
              let input = preparedInput else {
            phase = .error(.invalidConsent)
            return
        }
        guard settings.value.smartDropMode == preview.mode else {
            phase = .error(.invalidConsent)
            return
        }
        guard settings.value.language.resolvedIdentifier == preview.responseLanguage else {
            phase = .error(.invalidConsent)
            return
        }
        if preview.mode == .live, !liveModeAvailable {
            phase = .error(.liveModeUnavailable)
            return
        }
        if preview.mode == .live, credentialStatusProvider.status() == .notConfigured {
            phase = .error(.missingCredential)
            return
        }
        let consent = SmartDropConsent(
            contentDigest: input.descriptor.contentDigest,
            displayName: input.descriptor.displayName,
            purpose: preview.purpose,
            mode: preview.mode,
            model: preview.model,
            responseLanguage: preview.responseLanguage,
            confirmedAt: Date()
        )
        guard consent.authorizes(
            input,
            purpose: preview.purpose,
            mode: preview.mode,
            model: preview.model,
            responseLanguage: preview.responseLanguage
        ) else {
            phase = .error(.invalidConsent)
            return
        }

        phase = .analyzing(input.descriptor)
        requestCount += 1
        let id = transactionID
        let analyzer = preview.mode == .live ? liveAnalyzer : demoAnalyzer
        let request = SmartDropAnalysisRequest(
            input: input,
            consent: consent,
            responseLanguage: preview.responseLanguage
        )
        workTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let rawResult = try await analyzer.analyze(request)
                try Task.checkCancellation()
                guard transactionID == id else { return }
                let result = try validator.validate(
                    rawResult,
                    for: input.descriptor.kind,
                    expectedMode: preview.mode,
                    expectedModel: preview.model
                )
                guard result.proposals.count == 3 else {
                    throw SmartDropError.invalidProposalCount
                }
                phase = .proposals(result)
            } catch is CancellationError {
                guard transactionID == id else { return }
                phase = .error(.requestCancelled)
            } catch let error as SmartDropError {
                guard transactionID == id else { return }
                phase = .error(error)
            } catch {
                guard transactionID == id else { return }
                phase = .error(.invalidResponse)
            }
            workTask = nil
        }
    }

    func cancelAnalysis() {
        workTask?.cancel()
        workTask = nil
        preparedInput = nil
        pendingPreview = nil
        phase = .idle
    }

    func select(_ proposal: SmartDropProposal) {
        guard case let .proposals(analysis) = phase,
              analysis.proposals.contains(proposal) else {
            phase = .error(.invalidResponse)
            return
        }
        phase = .executionConfirmation(proposal, analysis: analysis)
    }

    func cancelExecutionConfirmation() {
        guard case let .executionConfirmation(_, analysis) = phase else { return }
        phase = .proposals(analysis)
    }

    /// Semantic actions are precomputed. Confirmation only reveals the chosen
    /// local result; it performs no second request and no file mutation.
    func confirmExecution() {
        guard case let .executionConfirmation(proposal, analysis) = phase else {
            phase = .error(.invalidResponse)
            return
        }
        phase = .completed(proposal, analysis: analysis)
    }

    func showProposalsAgain() {
        guard case let .completed(_, analysis) = phase else { return }
        phase = .proposals(analysis)
    }

    func copyCompletedResult() {
        guard case let .completed(proposal, _) = phase else { return }
        let fields = proposal.result.fields
            .map { "\($0.label): \($0.value)" }
            .joined(separator: "\n")
        let output = [proposal.result.text, fields]
            .filter { !$0.isEmpty }
            .joined(separator: fields.isEmpty ? "" : "\n\n")
        do {
            try presenter.copyText(output)
            lastCopyError = nil
        } catch {
            lastCopyError = .resultCopyFailed
        }
    }
}
