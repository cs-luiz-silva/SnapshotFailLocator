import Foundation

public struct SnapshotSearchPath: Codable {
    public var path: URL

    public init(path: URL) {
        self.path = path
    }
}
