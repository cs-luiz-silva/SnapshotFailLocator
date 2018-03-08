import Foundation
import Cocoa
import Console

struct SnapshotFile {
    var path: URL
    var changeDate: Date
}

func main() throws {
    let console = Console()
    let fileManager = FileManager.default
    
    console.printLine("Locating files...")

    
    let devicesPath = ("~/Library/Developer/CoreSimulator/Devices/" as NSString).standardizingPath
    
    guard let filesEnumerator =
        fileManager.enumerator(at: URL(fileURLWithPath: devicesPath),
                               includingPropertiesForKeys: [.contentModificationDateKey],
                               options: .skipsHiddenFiles,
                               errorHandler: { (url, error) in
                                console.printLine("Error navigating \(url.relativePath): \(error)")
                                return false
        }) else {
        console.printLine("Error fetching enumerator for path \(devicesPath)!")
        return
    }
    
    #if swift(>=4.1)
    let lazyFilesEnum = filesEnumerator.lazy.compactMap { $0 as? URL }
    #else
    let lazyFilesEnum = filesEnumerator.lazy.flatMap { $0 as? URL }
    #endif
    
    var files: [SnapshotFile] = []
    
    for file in lazyFilesEnum {
        if !file.path.contains("failed_") || file.pathExtension != "png" {
            continue
        }
        let vals = try file.resourceValues(forKeys: [.contentModificationDateKey])
        guard let date = vals.contentModificationDate else {
            continue
        }
        
        files.append(SnapshotFile(path: file, changeDate: date))
    }
    
    files = files.sorted { $0.changeDate > $1.changeDate }
    
    if files.count == 0 {
        console.printLine("No snapshot files found.")
        return
    }
    
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.locale = Locale.current
    formatter.doesRelativeDateFormatting = true
    
    let provider = AnyConsoleDataProvider(count: files.count, header: "Snapshot files found - most recent first:") { index -> String in
        let file = files[index]
        
        let fileName = file.path.lastPathComponent
        let dirPath = file.path.pathComponents.dropLast().suffix(1).joined(separator: "/")
        
        let str = "\(formatter.string(from: file.changeDate)) - \(dirPath)/\(fileName)"
        
        return str
    }
    
    let config = Pages.PageDisplayConfiguration(
        clearOnDisplay: true,
        commandPrompt: "Specify an entry number to open its containing folder") { str -> Pages.PagesCommandResult in
            if str.isEmpty {
                return .quit(nil)
            }
            
            guard let int = Int(str) else {
                return .loop("Invalid entry index str: must be an integer")
            }
            if int < 1 || int > files.count {
                return .loop("Invalid entry index \(int): must be between 1 and \(files.count)")
            }
            
            let index = int - 1
            
            let file = files[index]
            
            let folder = (file.path.path as NSString).deletingLastPathComponent
            NSWorkspace.shared.selectFile(file.path.path, inFileViewerRootedAtPath: (folder as NSString).deletingLastPathComponent)
            
            return .loop("Opening folder \(folder)...")
        }
    
    let pages = console.makePages(configuration: config)
    pages.displayPages(withProvider: provider)
}

do {
    try main()
} catch {
    print("Fatal error: \(error)")
}
