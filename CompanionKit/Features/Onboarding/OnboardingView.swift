import SwiftUI

struct OnboardingView: View {
    let complete: () -> Void
    @State private var page = 0

    private let pageCount = 4

    var body: some View {
        ScrollView {
            VStack(spacing: CompanionSpacing.xLarge) {
                pageArtwork

                VStack(spacing: CompanionSpacing.medium) {
                    Text(pageTitle)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(pageMessage)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 500)
                }

                HStack {
                    if page > 0 {
                        Button("Back") { page -= 1 }
                    }
                    Spacer()
                    Text("\(page + 1) of \(pageCount)")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Page \(page + 1) of \(pageCount)")
                    Spacer()
                    Button(page == pageCount - 1 ? "Meet Veya" : "Continue") {
                        if page == pageCount - 1 { complete() } else { page += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(40)
        }
        .frame(minWidth: 600, idealWidth: 660, minHeight: 450, idealHeight: 500)
    }

    @ViewBuilder
    private var pageArtwork: some View {
        if page == 0 {
            VeyaOnboardingMark()
                .frame(width: 100, height: 100)
                .accessibilityLabel("Veya, an original wingless soul companion")
        } else {
            Image(systemName: pageIcon)
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
        }
    }

    private var pageIcon: String {
        switch page {
        case 1: "lock.shield.fill"
        case 2: "bell.badge.fill"
        default: "menubar.rectangle"
        }
    }

    private var pageTitle: String {
        switch page {
        case 0: "Meet Veya"
        case 1: "Local, Clear, and Under Your Control"
        case 2: "Permissions Appear Only When Needed"
        default: "Always Within Reach"
        }
    }

    private var pageMessage: String {
        switch page {
        case 0:
            "Veya is CompanionKit’s original, wingless soul companion. Veya opens safe everyday actions and can be renamed whenever you like."
        case 1:
            "CompanionKit has no account, analytics, ads, backend, or cloud service. Settings stay on this Mac, and every action begins with you."
        case 2:
            "Only timer notifications request permission, and only when you start a timer. You can decline and keep using the app, or revoke access later in System Settings."
        default:
            "Activate Veya to open actions. The menu-bar orb offers keyboard-friendly access to actions, timer, settings, hide, and quit at any time."
        }
    }
}

private struct VeyaOnboardingMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.white, .blue.opacity(0.55), .clear], center: .center, startRadius: 4, endRadius: 52))
                .blur(radius: 2)
            Circle()
                .fill(RadialGradient(colors: [.white, Color(red: 0.7, green: 0.87, blue: 1), .blue.opacity(0.72)], center: .topLeading, startRadius: 2, endRadius: 50))
                .frame(width: 72, height: 70)
                .offset(x: 8, y: -2)
                .overlay {
                    HStack(spacing: 13) {
                        Capsule().fill(Color(red: 0.05, green: 0.12, blue: 0.3)).frame(width: 6, height: 12)
                        Capsule().fill(Color(red: 0.05, green: 0.12, blue: 0.3)).frame(width: 6, height: 12)
                    }
                    .offset(x: 11)
                }
        }
    }
}
