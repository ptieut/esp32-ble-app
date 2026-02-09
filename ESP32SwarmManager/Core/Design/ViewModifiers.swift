import SwiftUI

// MARK: - Card Style

struct CardStyleModifier: ViewModifier {
    var isSelected: Bool = false

    func body(content: Content) -> some View {
        content
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .stroke(
                        isSelected ? Theme.primary.opacity(0.3) : Theme.border.opacity(0.3),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Glass Style

struct GlassStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
    }
}

// MARK: - Surface Style

struct SurfaceStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .stroke(Theme.border.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Input Style

struct InputStyleModifier: ViewModifier {
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(Theme.spacingLG)
            .background(Theme.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                    .stroke(
                        isFocused ? Theme.primary : Theme.border,
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(isSelected: Bool = false) -> some View {
        modifier(CardStyleModifier(isSelected: isSelected))
    }

    func glassStyle() -> some View {
        modifier(GlassStyleModifier())
    }

    func surfaceStyle() -> some View {
        modifier(SurfaceStyleModifier())
    }

    func inputStyle(isFocused: Bool = false) -> some View {
        modifier(InputStyleModifier(isFocused: isFocused))
    }
}
