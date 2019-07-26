import Foundation

public class CustomSearchPathController: SearchPathController {
    public var url: URL
    public var name: String { return url.path }

    public init(url: URL) {
        self.url = url
    }

    public func enumerateSnapshotFiles() -> AnySequence<SnapshotFile> {
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
