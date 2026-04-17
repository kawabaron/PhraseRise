import Foundation
import SwiftUI

enum SongSourceType: String, Codable, CaseIterable, Identifiable {
    case imported
    case micRecorded

    var id: String { rawValue }

    var label: String {
        switch self {
        case .imported:
            return "Filesから追加"
        case .micRecorded:
            return "練習音源を録音"
        }
    }
}

enum PhraseStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case mastered
    case archived

    var id: String { rawValue }

    var label: String {
        switch self {
        case .active:
            return "active"
        case .mastered:
            return "mastered"
        case .archived:
            return "archived"
        }
    }

    var tint: Color {
        switch self {
        case .active:
            return AppColors.accent
        case .mastered:
            return AppColors.success
        case .archived:
            return AppColors.warning
        }
    }
}

enum PracticeResultType: String, Codable, CaseIterable, Identifiable {
    case stable
    case barely
    case failed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .stable:
            return "stable"
        case .barely:
            return "barely"
        case .failed:
            return "failed"
        }
    }

    var tint: Color {
        switch self {
        case .stable:
            return AppColors.success
        case .barely:
            return AppColors.warning
        case .failed:
            return AppColors.recording
        }
    }
}

enum SubscriptionProductType: String, Codable, CaseIterable, Identifiable {
    case none
    case lifetime
    case monthly

    var id: String { rawValue }
}
