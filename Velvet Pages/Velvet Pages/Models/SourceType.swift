import Foundation

enum SourceType: String, Codable, CaseIterable, Identifiable {
    case currentSource
    case ao3

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .currentSource: return "Current Source"
        case .ao3: return "AO3"
        }
    }
}
