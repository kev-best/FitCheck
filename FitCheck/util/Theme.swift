import SwiftUI

final class Theme: ObservableObject {
    @Published var gradient = LinearGradient(
        colors: [
            Color(hue: 0.77, saturation: 0.85, brightness: 0.95),
            Color(hue: 0.58, saturation: 0.85, brightness: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    @Published var bg = Color("AppBackground")
    @Published var surface = Color(.secondarySystemBackground)
    @Published var textPrimary = Color.primary
    @Published var textSecondary = Color.secondary
    @Published var cornerRadius: CGFloat = 24
    @Published var shadow = Color.black.opacity(0.08)

    // Reserved for future typography helpers
    func titleStyle() -> some View { EmptyView() }
}

extension View {
    func softCard(cornerRadius: CGFloat = 24, shadow: Color = .black.opacity(0.08)) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: shadow, radius: 12, x: 0, y: 8)
    }

    func pill(_ theme: Theme) -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(theme.gradient)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(radius: 6)
    }
}
