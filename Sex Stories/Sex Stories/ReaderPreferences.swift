import Foundation

enum ReaderFontFamily: String, CaseIterable, Identifiable {
    case serif
    case sans
    case rounded

    var id: String { rawValue }

    var label: String {
        switch self {
        case .serif: return "Serif"
        case .sans: return "Sans"
        case .rounded: return "Rounded"
        }
    }
}
