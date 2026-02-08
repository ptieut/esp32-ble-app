import SwiftUI

struct OverallProgressView: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(alignment: .bottom) {
                Text("Update Progress")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.primary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: 0x1E293B))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.primary)
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.easeOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 12)

            HStack {
                Text("Updating swarm...")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                Text("\(completedCount)/\(totalCount) Devices")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

#Preview {
    OverallProgressView(progress: 0.6, completedCount: 3, totalCount: 5)
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
