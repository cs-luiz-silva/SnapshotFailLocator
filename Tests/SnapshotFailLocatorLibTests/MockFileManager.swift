import Foundation
import SnapshotFailLocatorLib

class MockFileManager: FileManagerType {
    var failRemoveItem: Bool = false

    var didCallRemoveItem: [URL] = []

    func removeItem(at url: URL) throws {
        didCallRemoveItem.append(url)
        if failRemoveItem {
            throw Error.mockError
        }
    }

    private enum Error: Swift.Error {
        case mockError
    }
}
