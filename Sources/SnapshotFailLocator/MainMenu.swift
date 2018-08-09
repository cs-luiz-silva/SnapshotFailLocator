import Foundation
import Cocoa
import Console

/// Manages displaying of snapshots from a snapshot repository into a paged list
/// with support for spawning of commands from CLI input.
class MainMenu {
    var console: ConsoleClient
    var repository: SnapshotRepository
    
    var files: [SnapshotFile] {
        return repository.files
    }
    
    init(console: ConsoleClient, repository: SnapshotRepository) {
        self.console = console
        self.repository = repository
    }
    
    func run() {
        locateFiles()
        
        let pages = makeSnapshotPages(from: files)
        showSnapshotFiles(in: pages)
    }
    
    func locateFiles() {
        console.printLine("Locating files...")
        repository.reloadFromDisk()
    }
    
    // MARK: Functionalities
    
    private func browseToSnapshot(index: Int) {
        let file = files[index]
        
        let folder = file.folder
        
        NSWorkspace.shared
            .selectFile(
                file.failurePath.path,
                inFileViewerRootedAtPath: (folder as NSString).deletingLastPathComponent)
    }
    
    private func eraseAll() -> Bool {
        let prompt =
            console
                .readSureLineWith(prompt:
                    "\nAre you sure you want to \("delete".terminalColorize(.red)) all snapshot files (yes/no)?")
        
        guard prompt.lowercased().matches("yes", "y") else {
            return false
        }
        
        // Erase all files
        console.printLine("Erasing files...")
        
        do {
            try repository.eraseFiles()
        } catch {
            console.printLine("Error erasing files: \(error)")
            _=console.readLineWith(prompt: "")
        }
        
        return true
    }
    
    // MARK: User input/CLI management
    
    private func processUserInputOnPages(_ input: String) -> Pages.PagesCommandResult {
        
        // Quit
        if input.isEmpty || input.matches("quit", "q") {
            return .quit(nil)
        }
        
        // Help
        if input.matches("help", "h") {
            console.clearScreen()
            return .showMessageThenLoop(makeHelpString())
        }
        
        // Refresh
        if input.matches("refresh", "r") {
            console.clearScreen()
            return .modifyList { pages in
                self.locateFiles()
                self.showSnapshotFiles(in: pages)
            }
        }
        
        // Erase all
        if input.matches("eraseall", "e") {
            if eraseAll() {
                return .modifyList { pages in
                    //self.locateFiles()
                    self.showSnapshotFiles(in: pages)
                }
            }
            
            return .loop(nil)
        }
        
        // Assume an entry integer is entered, then.
        guard let int = Int(input) else {
            return .loop("Invalid entry index '\(input)': expected an entry index from above.".terminalColorize(.red))
        }
        
        if files.isEmpty {
            return .loop("No snapshot files are available. Type 'refresh' to reload from disk now.".terminalColorize(.red))
        }
        
        if int < 1 || int > files.count {
            return .loop("Invalid entry index \(int): must be between 1 and \(files.count).".terminalColorize(.red))
        }
        
        let index = int - 1
        
        self.browseToSnapshot(index: index)
        
        return .loop("Opening folder \(files[index].folder)...".terminalColorize(.magenta))
    }
    
    private func showSnapshotFiles(in pages: Pages) {
        let provider = makeSnapshotPagesProvider(from: files)
        pages.displayPages(withProvider: provider)
    }
    
    private func makeSnapshotPages(from files: [SnapshotFile]) -> Pages {
        let prompt = """
            Specify an entry number to open its containing folder
            Type \("help".terminalColorize(.green)) to see reference for available commands.
            """
        
        let config = Pages.PageDisplayConfiguration(
            clearOnDisplay: true,
            commandPrompt: prompt) { [weak self] str -> Pages.PagesCommandResult in
                return self?.processUserInputOnPages(str) ?? .quit(nil)
            }
        
        let pages = console.makePages(configuration: config)
        
        return pages
    }
    
    private func makeSnapshotPagesProvider(from files: [SnapshotFile]) -> AnyConsoleDataProvider<[String]> {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        formatter.doesRelativeDateFormatting = true
        
        let count = files.isEmpty ? 1 : files.count
        
        let provider = AnyConsoleDataProvider(count: count, header: "Snapshot files found - most recent first:") { index -> [String] in
            if files.isEmpty {
                return ["No snapshots available.".terminalColorize(.red)]
            }
            
            let file = files[index]
            
            let fileName = file.failurePath.lastPathComponent
            let dirPath =
                file.failurePath.pathComponents
                    .dropLast().suffix(1)
                    .joined(separator: "/")
                    .terminalColorize(ConsoleColor.green)
            
            var columns: [String] = []
            
            columns.append(formatter.string(from: file.changeDate).terminalColorize(.magenta))
            columns.append("\(dirPath)/\(fileName)")
            
            return columns
        }
        
        return provider
    }
    
    private func makeHelpString() -> String {
        return """
            Available commands and functionalities:

            \("quit".terminalColorize(.magenta)), \("q".terminalColorize(.magenta))
            Quits program.
            Entering '0' or hitting enter with an empty text also quits the program.

            \("<number>".terminalColorize(.magenta))
            = Open snapshot file
                Insert a \("number".terminalColorize(.blue)) from the list to open
                the containing folder for that snapshot file on Finder.

            \("refresh".terminalColorize(.magenta)), \("r".terminalColorize(.magenta))
            = Refresh files
                Reloads snapshot files list by reloading the list from disk.

            \("eraseall".terminalColorize(.magenta)), \("e".terminalColorize(.magenta))
            = Delete files
                \("Deletes".terminalColorize(.red)) all snapshot files on disk.
                Prompts for confirmation beforehands.
                Note: Does a lookup on disk prior to deletion, removing all snapshot
                      files found, even if not currently listed.

            \("help".terminalColorize(.magenta)), \("h".terminalColorize(.magenta))
            Displays this help prompt.

            """
    }
}

private extension String {
    func matches(_ str: String...) -> Bool {
        return str.contains(self)
    }
}
