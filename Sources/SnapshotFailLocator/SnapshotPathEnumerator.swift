import Foundation
import Cocoa

class SnapshotPathEnumerator {
    
    static func enumerateSnapshotFiles() -> AnySequence<SnapshotFile> {
        let snapshots =
            DeviceIterator().lazy.flatMap { iterator in
                return iterator.lazy
            }
        
        return AnySequence<SnapshotFile>(snapshots)
    }
    
}

struct DeviceIterator: Sequence, IteratorProtocol {
    
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
    
    mutating func next() -> ApplicationSnaphotIterator? {
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
                
                return ApplicationSnaphotIterator(enumerator: filesEnumerator)
            }
        }
        
        return nil
    }
}

struct ApplicationSnaphotIterator: Sequence, IteratorProtocol {
    
    fileprivate var enumerator: FileManager.DirectoryEnumerator
    fileprivate var iterator: NSFastEnumerationIterator
    
    init(enumerator: FileManager.DirectoryEnumerator) {
        self.enumerator = enumerator
        iterator = enumerator.makeIterator()
    }
    
    mutating func next() -> SnapshotFile? {
        while let file = iterator.next() as? URL {
            if !file.path.contains("failed_") || file.pathExtension != "png" {
                continue
            }
            
            do {
                let vals = try file.resourceValues(forKeys: [.contentModificationDateKey])
                guard let date = vals.contentModificationDate else {
                    continue
                }
                
                return SnapshotFile(path: file, changeDate: date)
            } catch {
                continue
            }
        }
        
        return nil
        
    }
    
}
