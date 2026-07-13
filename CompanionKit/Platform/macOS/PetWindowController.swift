import AppKit
import Combine
import SwiftUI

@MainActor
final class PetWindowController: NSObject, NSWindowDelegate, NSPopoverDelegate {
    private let environment: AppEnvironment
    private let panel: NSPanel
    private let hostingView: PetHostingView<PetView>
    private let actionPopover = NSPopover()
    private var settingsObservation: AnyCancellable?
    private var positionPersistTask: Task<Void, Never>?
    private var adjustingFrame = false

    init(environment: AppEnvironment) {
        self.environment = environment
        let size = environment.settings.value.petSize.points
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        hostingView = PetHostingView(
            rootView: PetView(environment: environment, activate: {})
        )
        super.init()

        hostingView.rootView = PetView(environment: environment) { [weak self] in
            self?.toggleActions()
        }
        configurePanel()
        configurePopover()
        observeChanges()
        restorePosition()
    }

    deinit {
        positionPersistTask?.cancel()
    }

    func show() {
        clampToVisibleScreen()
        panel.orderFrontRegardless()
        environment.setPetVisibility(true)
        environment.settings.update { settings in
            settings.petVisible = true
        }
    }

    func hide() {
        actionPopover.close()
        panel.orderOut(nil)
        environment.setPetVisibility(false)
        environment.settings.update { settings in
            settings.petVisible = false
        }
    }

    func toggleVisibility() {
        panel.isVisible ? hide() : show()
    }

    func resetPosition() {
        guard let visibleFrame = NSScreen.main?.visibleFrame ?? NSScreen.screens.first?.visibleFrame else { return }
        let origin = defaultOrigin(in: visibleFrame, size: panel.frame.size)
        panel.setFrameOrigin(origin)
        persistPosition(origin)
    }

    func showActions() {
        guard !actionPopover.isShown else { return }
        if !panel.isVisible { show() }
        environment.setCompanionState(.curious)
        NSApp.activate(ignoringOtherApps: true)
        actionPopover.show(relativeTo: hostingView.bounds, of: hostingView, preferredEdge: .maxX)
    }

    private func toggleActions() {
        if actionPopover.isShown {
            actionPopover.close()
            environment.setCompanionState(
                environment.timer.snapshot.status == .running ? .waiting : .idle
            )
        } else {
            showActions()
        }
    }

    func windowDidMove(_ notification: Notification) {
        guard !adjustingFrame else { return }
        clampToVisibleScreen()
        schedulePositionPersistence(panel.frame.origin)
    }

    func popoverDidClose(_ notification: Notification) {
        environment.setCompanionState(
            environment.timer.snapshot.status == .running ? .waiting : .idle
        )
    }

    private func configurePanel() {
        panel.delegate = self
        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow
        panel.setAccessibilityTitle("CompanionKit desktop companion")
    }

    private func configurePopover() {
        actionPopover.behavior = .transient
        actionPopover.delegate = self
        updatePopoverAnimation()
        actionPopover.contentSize = NSSize(width: 390, height: 580)
        actionPopover.contentViewController = NSHostingController(
            rootView: ActionPanelView(environment: environment)
        )
    }

    private func observeChanges() {
        settingsObservation = environment.settings.$value
            .removeDuplicates()
            .sink { [weak self] settings in
                self?.resize(for: settings.petSize)
                self?.updatePopoverAnimation()
            }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityDisplayOptionsDidChange),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
    }

    private func resize(for petSize: PetSize) {
        let size = NSSize(width: petSize.points, height: petSize.points)
        guard panel.frame.size != size else { return }
        var frame = panel.frame
        frame.size = size
        panel.setFrame(frame, display: true, animate: false)
        clampToVisibleScreen()
    }

    private func updatePopoverAnimation() {
        let settings = environment.settings.value
        actionPopover.animates = settings.animationEnabled
            && !settings.reducedInteractionMode
            && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    @objc private func screenParametersDidChange() {
        clampToVisibleScreen()
    }

    @objc private func accessibilityDisplayOptionsDidChange() {
        updatePopoverAnimation()
    }

    private func restorePosition() {
        let visibleFrame = NSScreen.main?.visibleFrame
            ?? NSScreen.screens.first?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1_440, height: 900)
        let requested = environment.settings.value.lastPetOrigin?.cgPoint
            ?? defaultOrigin(in: visibleFrame, size: panel.frame.size)
        let origin = PetPositionClamper.clamp(
            origin: requested,
            windowSize: panel.frame.size,
            visibleFrame: visibleFrame
        )
        panel.setFrameOrigin(origin)
    }

    private func clampToVisibleScreen() {
        guard !NSScreen.screens.isEmpty else { return }
        let currentFrame = panel.frame
        let screen = panel.screen
            ?? NSScreen.screens.max(by: {
                $0.frame.intersection(currentFrame).area < $1.frame.intersection(currentFrame).area
            })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        let clamped = PetPositionClamper.clamp(
            origin: currentFrame.origin,
            windowSize: currentFrame.size,
            visibleFrame: screen.visibleFrame
        )
        guard clamped != currentFrame.origin else { return }
        adjustingFrame = true
        panel.setFrameOrigin(clamped)
        adjustingFrame = false
        persistPosition(clamped)
    }

    private func defaultOrigin(in visibleFrame: NSRect, size: NSSize) -> NSPoint {
        NSPoint(
            x: visibleFrame.maxX - size.width - CompanionSpacing.large,
            y: visibleFrame.minY + CompanionSpacing.large
        )
    }

    private func persistPosition(_ origin: NSPoint) {
        environment.settings.update { settings in
            settings.lastPetOrigin = StoredPoint(origin)
        }
    }

    private func schedulePositionPersistence(_ origin: NSPoint) {
        positionPersistTask?.cancel()
        positionPersistTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self?.persistPosition(origin)
        }
    }
}

private final class PetHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }
}

private extension NSRect {
    var area: CGFloat { max(0, width) * max(0, height) }
}
