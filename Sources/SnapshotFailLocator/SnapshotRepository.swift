import Foundation

/// Repository which manages refences to snapshot files found on disk.
class SnapshotRepository {
    private(set) var files: [SnapshotFile] = []
    
    var filteredFiles: [SnapshotFile] = []
    
    /// If non-nil, specifies the currently active filter working on paths of
    /// snapshot filenames.
    var activeFilter: String? {
        didSet {
            reloadFilteredFiles()
        }
    }
    
    /// Initiates a reload of snapshot files from disk
    func reloadFromDisk() {
        files =
            SnapshotPathEnumerator.enumerateSnapshotFiles().sorted {
                $0.changeDate > $1.changeDate
            }
        
        reloadFilteredFiles()
    }
    
    /// Erases a given file index
    func eraseFile(index: Int) throws {
        let file = filteredFiles[index]
        
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
    
    /// Erases the files currently filtered by the active filter string
    func eraseDisplayedFiles() throws {
        for file in filteredFiles {
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
        reloadFilteredFiles()
    }
    
    private func reloadFilteredFiles() {
        if let activeFilter = activeFilter {
            filteredFiles = filterFiles(in: self, with: activeFilter)
        } else {
            filteredFiles = files
        }
    }
}
