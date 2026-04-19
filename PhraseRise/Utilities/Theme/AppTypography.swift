import SwiftUI

enum AppTypography {
    static let screenTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.bold)
    static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.subheadline, design: .default)
    static let caption = Font.system(.footnote, design: .rounded)
    static let eyebrow = Font.system(.caption2, design: .rounded).weight(.bold)
    static let heroMetric = Font.system(size: 28, weight: .bold, design: .rounded)
    static let metric = Font.system(size: 26, weight: .bold, design: .rounded)
}
