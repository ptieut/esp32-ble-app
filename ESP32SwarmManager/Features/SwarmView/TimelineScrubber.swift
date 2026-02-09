import SwiftUI

struct TimelineScrubber: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var onChanged: (Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: 0x1E293B))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.primary)
                    .frame(
                        width: geometry.size.width * CGFloat(normalizedValue),
                        height: 4
                    )

                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .offset(x: geometry.size.width * CGFloat(normalizedValue) - 8)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = Double(gesture.location.x / geometry.size.width)
                        let clamped = min(max(newValue, 0), 1)
                        value = clamped
                        onChanged(clamped)
                    }
            )
        }
    }

    private var normalizedValue: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return (value - range.lowerBound) / span
    }
}
