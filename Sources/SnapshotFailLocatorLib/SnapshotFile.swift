import Foundation

public struct SnapshotFile: Equatable {
    /// Path of `failed_*.png` file.
    public var failurePath: URL
    
    /// Path of `reference_*.png` file.
    public var referencePath: URL
    
    /// Path of `diff_*.png` file.
    public var diffPath: URL
    
    /// Folder which contains the failure image.
    public var folder: String
    
    /// Date the `failurePath` reference file was last modified on disk.
    public var changeDate: Date

    public init(failurePath: URL, referencePath: URL, diffPath: URL,
                folder: String, changeDate: Date) {

        self.failurePath = failurePath
        self.referencePath = referencePath
        self.diffPath = diffPath
        self.folder = folder
        self.changeDate = changeDate
    }
}
