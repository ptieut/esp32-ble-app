import SwiftUI

struct NetworkTrafficCard: View {
    let trafficMBps: Double = 24.0
    let changePercent: Double = 12.0

    private let barHeights: [CGFloat] = [0.4, 0.6, 0.3, 0.8, 0.5]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NETWORK TRAFFIC")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Theme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(trafficMBps)) MB/s")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                        Text("+\(Int(changePercent))%")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.success)
                }
            }

            Spacer()

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.primary.opacity(barOpacity(index: index)))
                        .frame(width: 14, height: 40 * height)
                }
            }
            .frame(height: 40)
        }
        .padding(Theme.spacingLG)
        .cardStyle()
    }

    private func barOpacity(index: Int) -> Double {
        let opacities = [0.2, 0.4, 0.6, 1.0, 0.8]
        return opacities[index]
    }
}

#Preview {
    NetworkTrafficCard()
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
