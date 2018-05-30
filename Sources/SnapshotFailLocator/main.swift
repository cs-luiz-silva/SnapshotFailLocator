import Foundation
import Cocoa
import Console

func main() throws {
    let console = Console()
    
    console.printLine("Locating files...")

    let files =
        SnapshotPathEnumerator.enumerateSnapshotFiles().sorted {
            $0.changeDate > $1.changeDate
        }
    
    if files.count == 0 {
        console.printLine("No snapshot files found.")
        return
    }
    
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.locale = Locale.current
    formatter.doesRelativeDateFormatting = true
    
    let provider = AnyConsoleDataProvider(count: files.count, header: "Snapshot files found - most recent first:") { index -> [String] in
        let file = files[index]
        
        let fileName = file.path.lastPathComponent
        let dirPath = file.path.pathComponents.dropLast().suffix(1).joined(separator: "/").terminalColorize(ConsoleColor.green)
        
        var columns: [String] = []
        
        columns.append(formatter.string(from: file.changeDate).terminalColorize(ConsoleColor.magenta))
        columns.append("\(dirPath)/\(fileName)")
        
        return columns
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
