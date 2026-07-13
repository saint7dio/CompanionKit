import SwiftUI

struct PetView: View {
    @ObservedObject var environment: AppEnvironment
    @ObservedObject private var settingsStore: SettingsStore
    let activate: () -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var floating = false
    @State private var auraPulse = false
    @State private var particleOrbit = false
    @State private var gazeOffset = CGSize.zero

    init(environment: AppEnvironment, activate: @escaping () -> Void) {
        self.environment = environment
        settingsStore = environment.settings
        self.activate = activate
    }

    private var settings: CompanionSettings { settingsStore.value }
    private var size: CGFloat { settings.petSize.points }
    private var personality: CompanionPersonality { settings.personality.parameters }
    private var reduceMotion: Bool { systemReduceMotion || settings.reduceMotionOverride }
    private var shouldAnimate: Bool {
        settings.animationEnabled
            && !settings.reducedInteractionMode
            && !reduceMotion
            && environment.petState != .hidden
    }
    private var palette: EtherealPalette { EtherealPalette(base: settings.baseColor) }
    private var profile: CompanionVisualProfile { CompanionVisualProfile(state: environment.petState) }

    var body: some View {
        ZStack {
            orbShadow
            aura
            particles
            spiritTail
            orbBody
            luminousCore
            face
            stateOverlay
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: size * 0.08))
        .offset(y: shouldAnimate && floating ? -profile.floatAmplitude * personality.movementAmplitude : 0)
        .scaleEffect(profile.scale)
        .rotationEffect(.degrees(profile.tiltDegrees))
        .opacity(environment.petState == .hidden ? 0 : 1)
        .onTapGesture {
            environment.setCompanionState(.surprised)
            activate()
        }
        .onContinuousHover { phase in
            switch phase {
            case let .active(location): updateGaze(for: location)
            case .ended: resetGaze()
            }
        }
        .contextMenu {
            Button("Open Actions", action: activate)
            Button("Settings…", action: environment.openSettings)
            Divider()
            Button("Hide Veya", action: environment.hidePet)
        }
        .onAppear { updateAnimations() }
        .onChange(of: shouldAnimate) { updateAnimations() }
        .onChange(of: environment.petState) { updateAnimations() }
        .onChange(of: settings.personality) { updateAnimations() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(settings.petName), Veya soul companion")
        .accessibilityValue(environment.petState.accessibilityDescription)
        .accessibilityHint("Activate to open everyday actions. The menu bar provides a keyboard-accessible alternative.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, activate)
        .animation(reduceMotion ? nil : .easeInOut(duration: CompanionMotion.stateTransition), value: environment.petState)
    }

    private var orbShadow: some View {
        Ellipse()
            .fill(.black.opacity(environment.petState == .sleeping ? 0.1 : 0.18))
            .frame(width: size * 0.5, height: size * 0.09)
            .offset(y: size * 0.39)
            .blur(radius: 4)
            .accessibilityHidden(true)
    }

    private var aura: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [palette.aura.opacity(0.34), palette.aura.opacity(0.08), .clear],
                    center: .center,
                    startRadius: size * 0.18,
                    endRadius: size * 0.52
                )
            )
            .frame(width: size * 1.06, height: size * 1.06)
            .scaleEffect(shouldAnimate && auraPulse ? 1.04 : 0.97)
            .opacity(profile.auraOpacity * settings.auraIntensity.scale)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var particles: some View {
        if settings.particleIntensity != .off && environment.petState != .sleeping {
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 2) ? palette.highlight : palette.accent)
                        .frame(width: index.isMultiple(of: 3) ? 3.5 : 2.2)
                        .offset(x: particleX(index), y: particleY(index))
                        .opacity(profile.particleOpacity * settings.particleIntensity.scale * personality.particleIntensity)
                }
            }
            .rotationEffect(.degrees(shouldAnimate && particleOrbit ? 18 : -8))
            .accessibilityHidden(true)
        }
    }

    private var spiritTail: some View {
        SpiritTailShape()
            .fill(
                LinearGradient(
                    colors: [palette.body.opacity(0.7), palette.aura.opacity(0.24), .clear],
                    startPoint: .trailing,
                    endPoint: .leading
                )
            )
            .frame(width: size * 0.63, height: size * 0.38)
            .offset(x: -size * 0.23, y: size * 0.18)
            .scaleEffect(x: profile.tailScale, y: 1, anchor: .trailing)
            .accessibilityHidden(true)
    }

    private var orbBody: some View {
        SoulOrbShape(deformation: profile.deformation)
            .fill(
                RadialGradient(
                    colors: [palette.highlight, palette.body, palette.edge],
                    center: UnitPoint(x: 0.38, y: 0.28),
                    startRadius: 1,
                    endRadius: size * 0.48
                )
            )
            .overlay(
                SoulOrbShape(deformation: profile.deformation)
                    .stroke(palette.highlight.opacity(differentiateWithoutColor ? 0.95 : 0.68), lineWidth: differentiateWithoutColor ? 2.4 : 1.4)
            )
            .frame(width: size * 0.72, height: size * 0.7)
            .offset(x: size * 0.06, y: -size * 0.02)
            .shadow(color: palette.aura.opacity(0.34), radius: 9)
            .accessibilityHidden(true)
    }

    private var luminousCore: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.78), palette.highlight.opacity(0.2), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.26
                )
            )
            .frame(width: size * 0.47, height: size * 0.43)
            .offset(x: -size * 0.01, y: size * 0.03)
            .opacity(environment.petState == .sleeping ? 0.34 : 0.78)
            .accessibilityHidden(true)
    }

    private var face: some View {
        VStack(spacing: size * 0.055) {
            HStack(spacing: size * 0.15) {
                eye(rotation: profile.leftEyeRotation)
                eye(rotation: profile.rightEyeRotation)
            }
            mouth
        }
        .offset(x: size * 0.09 + gazeOffset.width, y: size * 0.01 + gazeOffset.height)
        .accessibilityHidden(true)
    }

    private func eye(rotation: Double) -> some View {
        Group {
            if profile.closedEyes {
                Capsule()
                    .fill(palette.face)
                    .frame(width: size * 0.095, height: size * 0.023)
                    .rotationEffect(.degrees(rotation))
            } else {
                Capsule()
                    .fill(palette.face)
                    .frame(width: size * profile.eyeWidth, height: size * profile.eyeHeight)
                    .overlay(alignment: .topLeading) {
                        Circle()
                            .fill(.white.opacity(0.82))
                            .frame(width: size * 0.025)
                            .padding(size * 0.018)
                    }
            }
        }
    }

    @ViewBuilder
    private var mouth: some View {
        if environment.petState == .success {
            Capsule().fill(palette.face.opacity(0.8)).frame(width: size * 0.085, height: 2)
        } else if environment.petState == .error {
            Capsule().fill(palette.face.opacity(0.7)).frame(width: size * 0.065, height: 2).rotationEffect(.degrees(-8))
        } else if environment.petState == .surprised {
            Circle().fill(palette.face.opacity(0.75)).frame(width: size * 0.04, height: size * 0.045)
        }
    }

    @ViewBuilder
    private var stateOverlay: some View {
        if let symbol = profile.symbolName {
            Image(systemName: symbol)
                .font(.system(size: size * 0.105, weight: .semibold))
                .foregroundStyle(profile.statusColor)
                .padding(size * 0.045)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                .offset(x: size * 0.31, y: -size * 0.26)
                .symbolEffect(.pulse, options: .nonRepeating, value: environment.petState)
                .accessibilityHidden(true)
        }
    }

    private func particleX(_ index: Int) -> CGFloat {
        let values: [CGFloat] = [-0.37, 0.31, -0.43, 0.39, -0.2, 0.22]
        return size * values[index]
    }

    private func particleY(_ index: Int) -> CGFloat {
        let values: [CGFloat] = [-0.27, -0.35, 0.1, 0.2, 0.36, -0.04]
        return size * values[index]
    }

    private func updateGaze(for location: CGPoint) {
        environment.setPetAttention(true)
        guard !reduceMotion && !settings.reducedInteractionMode else { return }
        let deltaX = (location.x - size / 2) / max(size / 2, 1)
        let deltaY = (location.y - size / 2) / max(size / 2, 1)
        gazeOffset = CGSize(
            width: max(-1, min(1, deltaX)) * size * 0.018,
            height: max(-1, min(1, deltaY)) * size * 0.014
        )
    }

    private func resetGaze() {
        gazeOffset = .zero
        environment.setPetAttention(false)
    }

    private func updateAnimations() {
        floating = false
        auraPulse = false
        particleOrbit = false
        guard shouldAnimate else { return }
        let tempo = max(personality.animationTempo, 0.1)
        withAnimation(.easeInOut(duration: CompanionMotion.idleDrift / tempo).repeatForever(autoreverses: true)) {
            floating = true
        }
        withAnimation(.easeInOut(duration: CompanionMotion.auraPulse / tempo).repeatForever(autoreverses: true)) {
            auraPulse = true
        }
        if profile.particleOpacity > 0 {
            withAnimation(.linear(duration: CompanionMotion.particleOrbit / tempo).repeatForever(autoreverses: true)) {
                particleOrbit = true
            }
        }
    }
}

private struct SoulOrbShape: Shape {
    var deformation: CGFloat

    var animatableData: CGFloat {
        get { deformation }
        set { deformation = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let d = deformation * rect.width
        path.move(to: CGPoint(x: rect.midX - d * 0.2, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY + d * 0.12),
            control1: CGPoint(x: rect.maxX * 0.8, y: rect.minY - d * 0.08),
            control2: CGPoint(x: rect.maxX + d * 0.08, y: rect.height * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX - d * 0.12, y: rect.maxY),
            control1: CGPoint(x: rect.maxX - d * 0.04, y: rect.height * 0.82),
            control2: CGPoint(x: rect.width * 0.72, y: rect.maxY + d * 0.06)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY - d * 0.08),
            control1: CGPoint(x: rect.width * 0.22, y: rect.maxY - d * 0.02),
            control2: CGPoint(x: rect.minX - d * 0.05, y: rect.height * 0.73)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX - d * 0.2, y: rect.minY),
            control1: CGPoint(x: rect.minX + d * 0.02, y: rect.height * 0.2),
            control2: CGPoint(x: rect.width * 0.22, y: rect.minY + d * 0.03)
        )
        return path
    }
}

private struct SpiritTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.height * 0.22))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.height * 0.68),
            control1: CGPoint(x: rect.width * 0.6, y: rect.height * 0.1),
            control2: CGPoint(x: rect.width * 0.26, y: rect.height * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.height * 0.78),
            control1: CGPoint(x: rect.width * 0.22, y: rect.height * 0.98),
            control2: CGPoint(x: rect.width * 0.72, y: rect.height * 0.96)
        )
        path.closeSubpath()
        return path
    }
}

private struct EtherealPalette {
    let body: Color
    let edge: Color
    let aura: Color
    let accent: Color
    let highlight: Color
    let face: Color

    init(base: CompanionBaseColor) {
        let colors: (Color, Color, Color)
        switch base {
        case .iceBlue: colors = (Color(red: 0.73, green: 0.88, blue: 1), .blue, .cyan)
        case .moonViolet: colors = (Color(red: 0.78, green: 0.75, blue: 1), .indigo, .purple)
        case .mistMint: colors = (Color(red: 0.7, green: 0.94, blue: 0.88), .teal, .mint)
        case .warmAmber: colors = (Color(red: 1, green: 0.86, blue: 0.6), .orange, .yellow)
        case .softRose: colors = (Color(red: 1, green: 0.76, blue: 0.84), .pink, .purple)
        case .monochrome: colors = (Color(white: 0.86), .gray, .white)
        }
        body = colors.0
        edge = colors.1.opacity(0.72)
        aura = colors.2
        accent = colors.2
        highlight = .white
        face = Color(red: 0.06, green: 0.13, blue: 0.3)
    }
}

private struct CompanionVisualProfile {
    let scale: CGFloat
    let deformation: CGFloat
    let tiltDegrees: Double
    let floatAmplitude: Double
    let auraOpacity: Double
    let particleOpacity: Double
    let tailScale: CGFloat
    let closedEyes: Bool
    let eyeWidth: CGFloat
    let eyeHeight: CGFloat
    let leftEyeRotation: Double
    let rightEyeRotation: Double
    let symbolName: String?
    let statusColor: Color

    init(state: CompanionState) {
        scale = state == .success ? 1.06 : state == .error ? 0.94 : state == .surprised ? 1.04 : 1
        deformation = state == .working ? 0.08 : state == .error ? -0.06 : 0.03
        tiltDegrees = state == .curious ? -4 : state == .thinking ? 3 : 0
        floatAmplitude = state == .sleeping || state == .waiting ? 1.2 : 3.2
        auraOpacity = state == .sleeping ? 0.34 : state == .error ? 0.55 : 1
        particleOpacity = [.thinking, .working, .success].contains(state) ? 1 : state == .idle ? 0.32 : 0.18
        tailScale = state == .working ? 1.12 : state == .sleeping ? 0.82 : 1
        closedEyes = state == .sleeping || state == .success
        eyeWidth = state == .surprised ? 0.085 : 0.068
        eyeHeight = state == .surprised ? 0.13 : state == .working ? 0.09 : 0.115
        leftEyeRotation = state == .error ? 9 : state == .success ? 12 : 0
        rightEyeRotation = state == .error ? -9 : state == .success ? -12 : 0
        switch state {
        case .thinking: symbolName = "ellipsis"
        case .working: symbolName = "bolt.fill"
        case .success: symbolName = "sparkles"
        case .error: symbolName = "exclamationmark"
        case .waiting: symbolName = "timer"
        case .sleeping: symbolName = "moon.zzz"
        default: symbolName = nil
        }
        switch state {
        case .success: statusColor = .green
        case .error: statusColor = .red
        case .waiting: statusColor = .orange
        case .thinking: statusColor = .purple
        default: statusColor = .blue
        }
    }
}
