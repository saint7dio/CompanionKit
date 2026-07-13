import AppKit
import SwiftUI

struct ActionPanelView: View {
    @ObservedObject var environment: AppEnvironment
    @ObservedObject private var settings: SettingsStore
    @ObservedObject private var executor: ActionExecutor
    @ObservedObject private var timer: CountdownTimerController

    @State private var timerMinutes = 10
    @State private var pendingConfirmationID: String?

    init(environment: AppEnvironment) {
        self.environment = environment
        settings = environment.settings
        executor = environment.executor
        timer = environment.timer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CompanionSpacing.medium) {
            header
            feedback
            ScrollView {
                LazyVStack(spacing: CompanionSpacing.small) {
                    ForEach(environment.registry.actions, id: \.id) { action in
                        ActionRow(action: action, environment: environment, settings: settings) {
                            begin(action)
                        }
                    }
                    timerCard
                }
                .padding(.vertical, CompanionSpacing.xSmall)
            }
            footer
        }
        .padding(CompanionSpacing.large)
        .frame(width: 390, height: 580)
        .background(.regularMaterial)
        .confirmationDialog(
            confirmationTitle,
            isPresented: confirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Run Action") { confirmPendingAction() }
            Button("Cancel", role: .cancel) { pendingConfirmationID = nil }
        } message: {
            Text("This action changes the visible state of other applications.")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi, I’m \(settings.value.petName)")
                    .font(.title2.bold())
                Text("What would you like to do?")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VeyaActionMark()
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var feedback: some View {
        switch executor.state {
        case .idle:
            EmptyView()
        case .running:
            StatusBanner(icon: "hourglass", title: "Working", message: "Please wait…", color: .blue)
        case let .succeeded(result):
            StatusBanner(icon: "checkmark.circle.fill", title: result.title, message: result.message, color: .green)
        case let .failed(title, message):
            StatusBanner(icon: "exclamationmark.triangle.fill", title: title, message: message, color: .red)
        }
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: CompanionSpacing.small) {
            Label("Countdown Timer", systemImage: "timer")
                .font(.headline)
            if timer.snapshot.status == .running {
                Text(timer.snapshot.formattedRemaining)
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .accessibilityLabel("\(timer.snapshot.formattedRemaining) remaining")
                Button("Cancel Timer", role: .destructive) { timer.cancel() }
            } else {
                HStack(spacing: CompanionSpacing.small) {
                    ForEach([5, 10, 25], id: \.self) { minutes in
                        Button("\(minutes)m") { timerMinutes = minutes }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Set timer to \(minutes) minutes")
                    }
                }
                HStack {
                    Stepper("Custom: \(timerMinutes) minutes", value: $timerMinutes, in: 1...180)
                    Button("Start") {
                        Task { await timer.start(minutes: timerMinutes) }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            if let warning = timer.notificationWarning {
                Label(warning, systemImage: "bell.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(CompanionSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: CompanionRadius.medium))
    }

    private var footer: some View {
        HStack {
            Button("Settings", systemImage: "gearshape") { environment.openSettings() }
            Spacer()
            Button("Quit CompanionKit") { NSApp.terminate(nil) }
        }
        .buttonStyle(.link)
    }

    private var confirmationTitle: String {
        guard let id = pendingConfirmationID,
              let action = environment.registry.action(id: id) else { return "Confirm Action" }
        return "Run “\(action.title)”?"
    }

    private var confirmationPresented: Binding<Bool> {
        Binding(
            get: { pendingConfirmationID != nil },
            set: { if !$0 { pendingConfirmationID = nil } }
        )
    }

    private func begin(_ action: any CompanionAction) {
        if environment.confirmationPolicy.requiresConfirmation(for: action) {
            pendingConfirmationID = action.id
        } else {
            Task { await executor.execute(action) }
        }
    }

    private func confirmPendingAction() {
        guard let id = pendingConfirmationID,
              let action = environment.registry.action(id: id) else { return }
        pendingConfirmationID = nil
        Task { await executor.execute(action, confirmed: true) }
    }
}

private struct VeyaActionMark: View {
    var body: some View {
        ZStack {
            Circle().fill(.blue.opacity(0.18))
            Circle()
                .fill(RadialGradient(colors: [.white, .cyan.opacity(0.55), .blue.opacity(0.85)], center: .topLeading, startRadius: 1, endRadius: 18))
                .frame(width: 25, height: 24)
            HStack(spacing: 5) {
                Capsule().fill(.indigo).frame(width: 2.5, height: 5)
                Capsule().fill(.indigo).frame(width: 2.5, height: 5)
            }
            .offset(x: 2)
        }
    }
}

private struct ActionRow: View {
    let action: any CompanionAction
    let environment: AppEnvironment
    @ObservedObject var settings: SettingsStore
    let perform: () -> Void

    @State private var availability = ActionAvailability.available

    var body: some View {
        Button(action: perform) {
            HStack(spacing: CompanionSpacing.medium) {
                Image(systemName: action.systemImageName)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(availability.isAvailable ? Color.indigo : Color.secondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title).font(.headline)
                    Text(availability.unavailableReason ?? action.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: availability.isAvailable ? "chevron.right" : "nosign")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(CompanionSpacing.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!availability.isAvailable)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: CompanionRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: CompanionRadius.medium)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        )
        .accessibilityLabel(action.title)
        .accessibilityHint(availability.unavailableReason ?? action.description)
        .task(id: availabilityRevision) {
            availability = await environment.executor.availability(of: action)
        }
    }

    private var availabilityRevision: String {
        "\(settings.value.preferredApplicationPath ?? "")|\(settings.value.clipboardSnippet)"
    }
}
