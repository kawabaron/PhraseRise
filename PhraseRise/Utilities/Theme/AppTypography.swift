import SwiftUI

enum AppTypography {
    static let screenTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 22, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body = Font.system(.callout, design: .rounded)
    static let bodyStrong = Font.system(.body, design: .rounded).weight(.semibold)
    static let caption = Font.system(.footnote, design: .rounded)
    static let captionStrong = Font.system(.footnote, design: .rounded).weight(.semibold)
    static let eyebrow = Font.system(.caption2, design: .rounded).weight(.bold)
    static let micro = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let heroMetric = Font.system(size: 34, weight: .bold, design: .rounded)
    static let heroDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
    static let metric = Font.system(size: 28, weight: .bold, design: .rounded)
}
