import Foundation

class CustomSearchPathController: SearchPathController {
    var url: URL
    var name: String { return url.path }

    init(url: URL) {
        self.url = url
    }

    func enumerateSnapshotFiles() -> AnySequence<SnapshotFile> {
        guard let filesEnumerator =
            FileManager.default.enumerator(at: url,
                                           includingPropertiesForKeys: [.contentModificationDateKey],
                                           options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                           errorHandler: { (url, error) in
                                            print("Error navigating \(url.relativePath): \(error)")
                                            return false
        }) else {
            fatalError("Error fetching enumerator for path \(url)!")
        }

        return AnySequence(SnaphotPathIterator(enumerator: filesEnumerator))
    }
}
