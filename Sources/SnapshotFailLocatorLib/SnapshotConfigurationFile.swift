import Foundation

public struct SnapshotConfigurationFile: Codable {
    public var searchPaths: [SnapshotSearchPath]

    public init(searchPaths: [SnapshotSearchPath]) {
        self.searchPaths = searchPaths
    }
}
