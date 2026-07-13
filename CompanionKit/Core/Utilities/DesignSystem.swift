import SwiftUI

enum CompanionSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
    static let xLarge: CGFloat = 28
}

enum CompanionRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 18
}

enum CompanionMotion {
    static let stateTransition = 0.22
    static let idleDrift = 2.4
    static let auraPulse = 3.2
    static let particleOrbit = 7.5
}

struct StatusBanner: View {
    let icon: String
    let title: String
    let message: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: CompanionSpacing.small) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: CompanionSpacing.xSmall) {
                Text(title).font(.headline)
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(CompanionSpacing.medium)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: CompanionRadius.medium))
        .accessibilityElement(children: .combine)
    }
}
