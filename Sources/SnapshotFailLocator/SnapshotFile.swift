import Foundation

struct SnapshotFile {
    /// Path of `failed_*.png` file.
    var failurePath: URL
    
    /// Path of `reference_*.png` file.
    var referencePath: URL
    
    /// Path of `diff_*.png` file.
    var diffPath: URL
    
    /// Folder which contains the failure image.
    var folder: String
    
    /// Date the `failurePath` reference file was last modified on disk.
    var changeDate: Date
}
