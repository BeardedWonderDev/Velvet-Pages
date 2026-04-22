import Foundation

final class ReaderBookmarkStore {
    private let defaults = UserDefaults.standard
    private let key = "readerBookmarks"

    func loadBookmarks() -> [ReaderBookmark] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ReaderBookmark].self, from: data)) ?? []
    }

    func saveBookmarks(_ bookmarks: [ReaderBookmark]) {
        let data = (try? JSONEncoder().encode(bookmarks)) ?? Data()
        defaults.set(data, forKey: key)
    }

    func bookmarks(for storyID: String) -> [ReaderBookmark] {
        loadBookmarks().filter { $0.storyID == storyID }
    }

    func upsert(_ bookmark: ReaderBookmark) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.id == bookmark.id }
        bookmarks.append(bookmark)
        saveBookmarks(bookmarks)
    }

    func delete(id: String) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.id == id }
        saveBookmarks(bookmarks)
    }
}
