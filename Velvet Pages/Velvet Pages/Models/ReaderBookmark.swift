import Foundation

struct ReaderBookmark: Identifiable, Codable, Hashable {
    let id: String
    let storyID: String
    let anchorID: String
    let title: String
    let createdAt: Date
}
