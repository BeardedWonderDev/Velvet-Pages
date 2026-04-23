import Foundation

struct Chapter: Identifiable, Hashable, Codable {
    var id: String
    var number: Int
    var title: String
    var url: String?
    var content: String?
    var isAvailable: Bool = true

    init(id: String = UUID().uuidString, number: Int, title: String, url: String? = nil, content: String? = nil, isAvailable: Bool = true) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.content = content
        self.isAvailable = isAvailable
    }
}
