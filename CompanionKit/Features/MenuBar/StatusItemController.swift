import AppKit

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let environment: AppEnvironment
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    init(environment: AppEnvironment) {
        self.environment = environment
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "circle.dotted", accessibilityDescription: "CompanionKit")
        statusItem.button?.toolTip = "CompanionKit"
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()
        let petVisible = environment.settings.value.petVisible
        addItem(petVisible ? "Hide Veya" : "Show Veya", action: #selector(togglePet), key: "p")
        addItem("Open Actions", action: #selector(openActions), key: "a")

        let timerMenu = NSMenu(title: "Timer")
        if environment.timer.snapshot.status == .running {
            let remaining = NSMenuItem(title: "Remaining: \(environment.timer.snapshot.formattedRemaining)", action: nil, keyEquivalent: "")
            remaining.isEnabled = false
            timerMenu.addItem(remaining)
            let cancel = NSMenuItem(title: "Cancel Timer", action: #selector(cancelTimer), keyEquivalent: "")
            cancel.target = self
            timerMenu.addItem(cancel)
        } else {
            for minutes in [5, 10, 25] {
                let item = NSMenuItem(title: "Start \(minutes)-Minute Timer", action: #selector(startTimer(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = minutes
                timerMenu.addItem(item)
            }
        }
        let timerItem = NSMenuItem(title: "Timer", action: nil, keyEquivalent: "")
        timerItem.submenu = timerMenu
        menu.addItem(timerItem)

        let animationTitle = environment.settings.value.animationEnabled
            ? "Pause Animations"
            : "Resume Animations"
        addItem(animationTitle, action: #selector(toggleAnimations))

        let personalityMenu = NSMenu(title: "Personality")
        for personality in CompanionPersonalityPreset.allCases {
            let item = NSMenuItem(title: personality.displayName, action: #selector(selectPersonality(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = personality.rawValue
            item.state = environment.settings.value.personality == personality ? .on : .off
            personalityMenu.addItem(item)
        }
        let personalityItem = NSMenuItem(title: "Personality", action: nil, keyEquivalent: "")
        personalityItem.submenu = personalityMenu
        menu.addItem(personalityItem)

        addItem("Reset Veya Position", action: #selector(resetPosition))
        addItem("Settings…", action: #selector(openSettings), key: ",")

        let actionsMenu = NSMenu(title: "Actions")
        for action in environment.registry.actions {
            let item = NSMenuItem(title: action.title, action: #selector(runAction(_:)), keyEquivalent: "")
            item.image = NSImage(systemSymbolName: action.systemImageName, accessibilityDescription: nil)
            item.target = self
            item.representedObject = action.id
            actionsMenu.addItem(item)
        }
        let actionsItem = NSMenuItem(title: "Quick Actions", action: nil, keyEquivalent: "")
        actionsItem.submenu = actionsMenu
        menu.addItem(actionsItem)

        menu.addItem(.separator())
        addItem("About CompanionKit", action: #selector(showAbout))
        addItem("Quit CompanionKit", action: #selector(quit), key: "q")
    }

    private func addItem(_ title: String, action: Selector, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    @objc private func togglePet() {
        environment.settings.value.petVisible ? environment.hidePet() : environment.showPet()
    }

    @objc private func openActions() { environment.showActions() }
    @objc private func openSettings() { environment.openSettings() }

    @objc private func toggleAnimations() {
        environment.setAnimationsEnabled(!environment.settings.value.animationEnabled)
    }

    @objc private func resetPosition() { environment.resetPetPosition() }

    @objc private func startTimer(_ sender: NSMenuItem) {
        guard let minutes = sender.representedObject as? Int else { return }
        Task { await environment.timer.start(minutes: minutes) }
    }

    @objc private func cancelTimer() { environment.timer.cancel() }

    @objc private func selectPersonality(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let personality = CompanionPersonalityPreset(rawValue: rawValue) else { return }
        environment.settings.update { $0.personality = personality }
    }

    @objc private func runAction(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let action = environment.registry.action(id: id) else { return }
        if environment.confirmationPolicy.requiresConfirmation(for: action) {
            environment.showActions()
        } else {
            environment.showActions()
            Task { await environment.executor.execute(action) }
        }
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "CompanionKit",
            .applicationVersion: "0.1.0",
            .credits: NSAttributedString(
                string: "A friendly Mac companion for everyday actions.\n\nVeya is an original wingless soul companion created for CompanionKit. Local-first, with no account, analytics, ads, or cloud service.\n\nMIT licensed. Open-source repository URL not configured."
            )
        ])
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
