import Foundation

enum StatsPeriodFilter: String, CaseIterable, Identifiable {
    case last7Days
    case last30Days
    case allTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .last7Days:
            return "7日"
        case .last30Days:
            return "30日"
        case .allTime:
            return "全期間"
        }
    }
}
