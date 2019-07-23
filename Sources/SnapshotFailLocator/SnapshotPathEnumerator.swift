import Foundation
import Cocoa

class SnapshotPathEnumerator {
    static func enumerateSnapshotFiles() -> AnySequence<SnapshotFile> {
        let snapshots =
            DerivedDataDeviceIterator().lazy.flatMap { iterator in
                return iterator.lazy
            }
        
        return AnySequence<SnapshotFile>(snapshots)
    }
}

struct SnaphotPathIterator: Sequence, IteratorProtocol {
    
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
                
                // Match `reference_` and `diff_` files which are also saved on
                // the same path as failed images
                let referencePath
                    = file.path.replacingOccurrences(of: "failed_", with: "reference_")
                let diffPath
                    = file.path.replacingOccurrences(of: "failed_", with: "diff_")
                
                let folder = (file.path as NSString).deletingLastPathComponent
                
                return SnapshotFile(failurePath: file,
                                    referencePath: URL(fileURLWithPath: referencePath),
                                    diffPath: URL(fileURLWithPath: diffPath),
                                    folder: folder,
                                    changeDate: date)
            } catch {
                continue
            }
        }
        
        return nil
    }
}
