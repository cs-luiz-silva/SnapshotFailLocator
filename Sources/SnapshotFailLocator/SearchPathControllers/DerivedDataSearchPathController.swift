import Foundation

class DerivedDataSearchPathController: SearchPathController {
    let name: String = "DerivedData"

    func enumerateSnapshotFiles() -> AnySequence<SnapshotFile> {
        let snapshots =
            DerivedDataDeviceIterator().lazy.flatMap { iterator in
                return iterator.lazy
        }

        return AnySequence<SnapshotFile>(snapshots)
    }
}

struct DerivedDataDeviceIterator: Sequence, IteratorProtocol {

    fileprivate var enumerator: FileManager.DirectoryEnumerator
    fileprivate var iterator: NSFastEnumerationIterator

    init() {
        let fileManager = FileManager.default

        let devicesPath = ("~/Library/Developer/CoreSimulator/Devices/" as NSString).standardizingPath

        guard let filesEnumerator =
            fileManager.enumerator(at: URL(fileURLWithPath: devicesPath),
                                   includingPropertiesForKeys: nil,
                                   options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants],
                                   errorHandler: { (url, error) in
                                    print("Error navigating \(url.relativePath): \(error)")
                                    return false
            }) else {

                fatalError("Error fetching enumerator for path \(devicesPath)!")
        }

        enumerator = filesEnumerator
        iterator = enumerator.makeIterator()
    }

    mutating func next() -> SnaphotPathIterator? {
        while let url = iterator.next() as? URL {
            let appUrl = url.appendingPathComponent("data/Containers/Data/Application")

            if FileManager.default.fileExists(atPath: appUrl.absoluteURL.path) {

                guard let filesEnumerator =
                    FileManager.default.enumerator(at: appUrl,
                                                   includingPropertiesForKeys: [.contentModificationDateKey],
                                                   options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                                   errorHandler: { (url, error) in
                                                    print("Error navigating \(url.relativePath): \(error)")
                                                    return false
                    }) else {
                        fatalError("Error fetching enumerator for path \(appUrl)!")
                }

                return SnaphotPathIterator(enumerator: filesEnumerator)
            }
        }

        return nil
    }
}
