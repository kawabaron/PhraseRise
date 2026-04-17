import SwiftUI

enum AppTypography {
    static let screenTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.caption, design: .rounded)
    static let eyebrow = Font.system(.caption, design: .rounded).weight(.semibold)
    static let bpmHero = Font.system(size: 38, weight: .bold, design: .rounded)
    static let heroMetric = Font.system(size: 30, weight: .bold, design: .rounded)
    static let metric = Font.system(size: 28, weight: .bold, design: .rounded)
}
