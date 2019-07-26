import Foundation

/// Repository which manages refences to snapshot files found on disk.
public class SnapshotRepository {
    private(set) public var files: [SnapshotFile] = []
    
    private(set) public var filteredFiles: [SnapshotFile] = []
    public let searchPathControllers: [SearchPathController]
    
    /// If non-nil, specifies the currently active filter working on paths of
    /// snapshot filenames.
    public var activeFilter: String? {
        didSet {
            reloadFilteredFiles()
        }
    }

    public var fileManager: FileManagerType

    public init(searchPathControllers: [SearchPathController], fileManager: FileManagerType) {
        self.searchPathControllers = searchPathControllers
        self.fileManager = fileManager
    }

    private func loadAllFiles() -> [SnapshotFile] {
        return searchPathControllers.flatMap { $0.enumerateSnapshotFiles() }
    }
    
    /// Initiates a reload of snapshot files from disk
    public func reloadFromDisk() {
        files =
            loadAllFiles().sorted {
                $0.changeDate > $1.changeDate
            }
        
        reloadFilteredFiles()
    }
    
    /// Erases a given file index
    public func eraseFile(index: Int) throws {
        let file = filteredFiles[index]
        
        try fileManager.removeItem(at: file.failurePath)
        try? fileManager.removeItem(at: file.diffPath)
        try? fileManager.removeItem(at: file.referencePath)
        
        reloadFromDisk()
    }
    
    /// Erases all files on disk, reloading the files from disk afterwards again.
    public func eraseFiles() throws {
        for file in files {
            try fileManager.removeItem(at: file.failurePath)
            try? fileManager.removeItem(at: file.diffPath)
            try? fileManager.removeItem(at: file.referencePath)
        }
        
        reloadFromDisk()
    }
    
    /// Erases the files currently filtered by the active filter string
    public func eraseDisplayedFiles() throws {
        for file in filteredFiles {
            try fileManager.removeItem(at: file.failurePath)
            try? fileManager.removeItem(at: file.diffPath)
            try? fileManager.removeItem(at: file.referencePath)
        }
        
        reloadFromDisk()
    }
    
    /// Clears the list of files within this repository.
    /// Does not erase any file from disk.
    public func clear() {
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
