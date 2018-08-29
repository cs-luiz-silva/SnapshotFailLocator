import Foundation

/// Repository which manages refences to snapshot files found on disk.
class SnapshotRepository {
    private(set) var files: [SnapshotFile] = []
    
    /// Initiates a reload of snapshot files from disk
    func reloadFromDisk() {
        files =
            SnapshotPathEnumerator.enumerateSnapshotFiles().sorted {
                $0.changeDate > $1.changeDate
            }
    }
    
    /// Erases a given file index
    func eraseFile(index: Int) throws {
        let file = files[index]
        
        try FileManager.default.removeItem(at: file.failurePath)
        try? FileManager.default.removeItem(at: file.diffPath)
        try? FileManager.default.removeItem(at: file.referencePath)
        
        reloadFromDisk()
    }
    
    /// Erases all files on disk, reloading the files from disk afterwards again.
    func eraseFiles() throws {
        for file in files {
            try FileManager.default.removeItem(at: file.failurePath)
            try? FileManager.default.removeItem(at: file.diffPath)
            try? FileManager.default.removeItem(at: file.referencePath)
        }
        
        reloadFromDisk()
    }
    
    /// Clears the list of files within this repository.
    /// Does not erase any file from disk.
    func clear() {
        files = []
    }
}
