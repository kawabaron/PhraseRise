import SwiftUI

struct InputLevelMeterView: View {
    let level: Double
    let isActive: Bool

    private let barCount = 24
    // マイク入力の平均パワーは -20dB 付近で頭打ちになりがちなので、
    // 表示上は少しブーストして視認しやすくする。
    private let displayBoost = 1.35

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let barSpacing: CGFloat = 4
            let barWidth = max((width - barSpacing * CGFloat(barCount - 1)) / CGFloat(barCount), 2)
            let boostedLevel = min(1, max(0, level) * displayBoost)
            let activeBars = Int(round(boostedLevel * Double(barCount)))

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0 ..< barCount, id: \.self) { index in
                    let ratio = Double(index) / Double(max(barCount - 1, 1))
                    let isOn = isActive && index < activeBars
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isOn ? color(for: ratio) : Color.white.opacity(0.10))
                        .frame(width: barWidth, height: barHeight(ratio: ratio, height: geometry.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(.easeOut(duration: 0.08), value: level)
        }
    }

    private func barHeight(ratio: Double, height: CGFloat) -> CGFloat {
        let minHeight = height * 0.35
        let maxHeight = height
        return minHeight + (maxHeight - minHeight) * CGFloat(ratio)
    }

    private func color(for ratio: Double) -> Color {
        if ratio < 0.6 {
            return AppColors.accent
        } else if ratio < 0.85 {
            return AppColors.warning
        } else {
            return AppColors.recording
        }
    }
}
