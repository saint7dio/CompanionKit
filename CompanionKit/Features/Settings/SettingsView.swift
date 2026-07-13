import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var environment: AppEnvironment
    @ObservedObject private var settings: SettingsStore

    @State private var launchAtLoginError: String?
    @State private var showResetConfirmation = false

    init(environment: AppEnvironment) {
        self.environment = environment
        settings = environment.settings
    }

    var body: some View {
        TabView {
            petSettings
                .tabItem { Label("Veya", systemImage: "sparkles") }
            actionSettings
                .tabItem { Label("Actions", systemImage: "bolt") }
            privacySettings
                .tabItem { Label("Privacy", systemImage: "hand.raised") }
        }
        .padding(CompanionSpacing.large)
        .frame(minWidth: 580, idealWidth: 620, minHeight: 500, idealHeight: 590)
        .alert("Reset CompanionKit?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                do {
                    try environment.resetAllSettings()
                    launchAtLoginError = nil
                } catch {
                    launchAtLoginError = CompanionError.userFacing(error).localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This restores default settings and clears the active timer. Onboarding will remain completed.")
        }
    }

    private var petSettings: some View {
        Form {
            Section("Meet Veya") {
                Text("Veya is CompanionKit’s original wingless soul companion. Your personal name can be changed at any time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Companion name", text: binding(\.petName))
                    .accessibilityHint("The personal name used by Veya.")
                Picker("Companion size", selection: binding(\.petSize)) {
                    ForEach(PetSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
            }

            Section("Ethereal Appearance") {
                Picker("Theme", selection: binding(\.theme)) {
                    ForEach(CompanionThemeID.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                Picker("Base color", selection: binding(\.baseColor)) {
                    ForEach(CompanionBaseColor.allCases) { color in
                        Text(color.displayName).tag(color)
                    }
                }
                Picker("Aura", selection: binding(\.auraIntensity)) {
                    ForEach(CompanionEffectIntensity.allCases) { intensity in
                        Text(intensity.displayName).tag(intensity)
                    }
                }
                Picker("Particles", selection: binding(\.particleIntensity)) {
                    ForEach(CompanionEffectIntensity.allCases) { intensity in
                        Text(intensity.displayName).tag(intensity)
                    }
                }
                Picker("Personality", selection: binding(\.personality)) {
                    ForEach(CompanionPersonalityPreset.allCases) { personality in
                        Text(personality.displayName).tag(personality)
                    }
                }
            }

            Section("Motion and Interaction") {
                Toggle("Enable subtle animations", isOn: animationBinding)
                Toggle("Always reduce motion", isOn: binding(\.reduceMotionOverride))
                    .help("Reduces CompanionKit motion in addition to the macOS Reduce Motion setting. System Reduce Motion is always respected.")
                Toggle("Reduced interaction mode", isOn: binding(\.reducedInteractionMode))
                    .help("Disables hover reactions and automatic movement while keeping clicks and menu access available.")
                Picker("Appearance", selection: appearanceBinding) {
                    ForEach(PreferredAppearance.allCases) { appearance in
                        Text(appearance.displayName).tag(appearance)
                    }
                }
            }

            Section("Position") {
                Button("Reset Veya Position") { environment.resetPetPosition() }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
                if let launchAtLoginError {
                    Label(launchAtLoginError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var actionSettings: some View {
        Form {
            Section("Favorite Application") {
                HStack {
                    Text(selectedApplicationName)
                        .foregroundStyle(settings.value.preferredApplicationPath == nil ? .secondary : .primary)
                    Spacer()
                    Button("Choose…", action: chooseApplication)
                    if settings.value.preferredApplicationPath != nil {
                        Button("Clear") { settings.update { $0.preferredApplicationPath = nil } }
                    }
                }
                Text("CompanionKit stores the selected path locally. If the app moves, choose it again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Clipboard Snippet") {
                TextEditor(text: binding(\.clipboardSnippet))
                    .frame(minHeight: 90)
                    .accessibilityLabel("Saved clipboard text")
                Text("This text is copied only when you explicitly run Copy Saved Text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Reset All Settings…", role: .destructive) { showResetConfirmation = true }
            }
        }
        .formStyle(.grouped)
    }

    private var privacySettings: some View {
        Form {
            Section("Local by Design") {
                Label("No account, analytics, advertising, or network service", systemImage: "checkmark.shield")
                Label("Settings stay in your macOS user preferences", systemImage: "externaldrive")
                Label("Clipboard content is not recorded", systemImage: "doc.on.clipboard")
            }
            Section("Optional Permission") {
                Label("Notifications", systemImage: "bell")
                Text("Requested only when you start a timer, so CompanionKit can alert you if it is in the background. The timer still works if you decline.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Open Notification Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            Section("More Information") {
                Text("See PRIVACY.md and docs/PERMISSIONS.md in the source repository for data and permission details.")
            }
        }
        .formStyle(.grouped)
    }

    private var selectedApplicationName: String {
        guard let path = settings.value.preferredApplicationPath else { return "No application selected" }
        return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }

    private var animationBinding: Binding<Bool> {
        Binding(
            get: { settings.value.animationEnabled },
            set: { environment.setAnimationsEnabled($0) }
        )
    }

    private var appearanceBinding: Binding<PreferredAppearance> {
        Binding(
            get: { settings.value.preferredAppearance },
            set: { appearance in
                settings.update { $0.preferredAppearance = appearance }
                environment.applyAppearance()
            }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { environment.launchAtLogin.isEnabled },
            set: { enabled in
                do {
                    try environment.launchAtLogin.setEnabled(enabled)
                    settings.update { $0.launchAtLogin = enabled }
                    launchAtLoginError = nil
                } catch {
                    launchAtLoginError = CompanionError.userFacing(error).localizedDescription
                }
            }
        )
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<CompanionSettings, Value>) -> Binding<Value> {
        Binding(
            get: { settings.value[keyPath: keyPath] },
            set: { newValue in settings.update { $0[keyPath: keyPath] = newValue } }
        )
    }

    private func chooseApplication() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Favorite Application"
        panel.prompt = "Choose"
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        settings.update { $0.preferredApplicationPath = url.path }
    }
}
