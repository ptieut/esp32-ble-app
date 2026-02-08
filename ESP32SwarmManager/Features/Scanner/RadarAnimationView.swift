import SwiftUI

struct RadarAnimationView: View {
    @State private var ring1Scale: CGFloat = 0.4
    @State private var ring2Scale: CGFloat = 0.4
    @State private var ring3Scale: CGFloat = 0.4
    @State private var ring1Opacity: Double = 0.6
    @State private var ring2Opacity: Double = 0.6
    @State private var ring3Opacity: Double = 0.6

    let isAnimating: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.primary.opacity(0.15))
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)

            Circle()
                .fill(Theme.primary.opacity(0.15))
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)

            Circle()
                .fill(Theme.primary.opacity(0.15))
                .scaleEffect(ring3Scale)
                .opacity(ring3Opacity)

            Circle()
                .fill(Theme.background)
                .frame(width: 96, height: 96)
                .overlay(
                    Circle()
                        .stroke(Theme.primary.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: Theme.primary.opacity(0.4), radius: 20)

            Image(systemName: "sensor.tag.radiowaves.forward")
                .font(.system(size: 40))
                .foregroundColor(Theme.primary)
        }
        .frame(width: 192, height: 192)
        .onAppear { startAnimations() }
        .onChange(of: isAnimating) { animating in
            if animating { startAnimations() }
        }
    }

    private func startAnimations() {
        guard isAnimating else { return }

        withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false)) {
            ring1Scale = 1.0
            ring1Opacity = 0
        }

        withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false).delay(1)) {
            ring2Scale = 1.0
            ring2Opacity = 0
        }

        withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false).delay(2)) {
            ring3Scale = 1.0
            ring3Opacity = 0
        }
    }
}

#Preview {
    RadarAnimationView(isAnimating: true)
        .preferredColorScheme(.dark)
        .background(Theme.background)
}
