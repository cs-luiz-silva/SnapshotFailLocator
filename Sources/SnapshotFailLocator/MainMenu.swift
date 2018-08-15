import Foundation
import Cocoa
import Console

/// Manages displaying of snapshots from a snapshot repository into a paged list
/// with support for spawning of commands from CLI input.
class MainMenu {
    var console: ConsoleClient
    var repository: SnapshotRepository
    
    var filteredFiles: [SnapshotFile] = []
    
    /// If non-nil, specifies the currently active filter working on paths of
    /// snapshot filenames.
    var activeFilter: String? {
        didSet {
            if let activeFilter = activeFilter {
                filteredFiles = filterFiles(in: repository, with: activeFilter)
            } else {
                filteredFiles = repository.files
            }
        }
    }
    
    init(console: ConsoleClient, repository: SnapshotRepository) {
        self.console = console
        self.repository = repository
    }
    
    func run() {
        locateFiles()
        
        let pages = makeSnapshotPages(from: filteredFiles)
        showSnapshotFiles(in: pages)
    }
    
    func locateFiles() {
        activeFilter = nil
        
        console.printLine("Locating files...")
        repository.reloadFromDisk()
        filteredFiles = repository.files
    }
    
    // MARK: Functionalities
    
    private func browseToSnapshot(index: Int) {
        let file = filteredFiles[index]
        
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
    
    private func processFilter(in input: String) -> Pages.PagesCommandResult? {
        let split =
            input
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: " ")
        
        if split.count == 1 {
            if !split[0].matches("filter", "f") {
                return nil
            }
            
            // One component only: User has input just `filter` or `f`
            // Result: Clear filter
            activeFilter = nil
            
            return .modifyList { _ in
                self.makeSnapshotPagesProvider()
            }
        }
        
        let filter = split.dropFirst().joined(separator: " ")
        
        if filter == activeFilter {
            return .loop(nil)
        }
        
        if filter.isEmpty {
            // Empty string clears filters
            activeFilter = nil
        } else {
            activeFilter = filter
        }
        
        return .modifyList { _ in
            self.makeSnapshotPagesProvider()
        }
    }
    
    // MARK: User input/CLI management
    
    private func processUserInputOnPages(_ input: String) -> Pages.PagesCommandResult {
        
        // Quit
        if input.matches("quit", "q") {
            return .quit(nil)
        }
        if input == "" {
            // If a filter is active, disable it instead of quitting
            if activeFilter != nil {
                activeFilter = nil
                
                return .modifyList { _ in
                    self.makeSnapshotPagesProvider()
                }
            }
            return .quit(nil)
        }
        
        // Help
        if input.matches("help", "h") {
            console.clearScreen()
            return .showMessageThenLoop(MainMenu.makeHelpString())
        }
        
        // Refresh
        if input.matches("refresh", "r") {
            console.clearScreen()
            return .modifyList { pages in
                self.locateFiles()
                return self.makeSnapshotPagesProvider()
            }
        }
        
        // Filter files
        if input.hasPrefix("filter") || input.hasPrefix("f") {
            if let result = processFilter(in: input) {
                return result
            }
        }
        
        // Erase all
        if input.matches("eraseall", "e") {
            if eraseAll() {
                return .modifyList { pages in
                    self.locateFiles()
                    return self.makeSnapshotPagesProvider()
                }
            }
            
            return .loop(nil)
        }
        
        // Assume an entry integer is entered, then.
        guard let int = Int(input) else {
            return .loop("Invalid entry index '\(input)': expected an entry index from above.".terminalColorize(.red))
        }
        
        if filteredFiles.isEmpty {
            return .loop("No snapshot files are available. Type 'refresh' to reload from disk now.".terminalColorize(.red))
        }
        
        if int < 1 || int > filteredFiles.count {
            return .loop("Invalid entry index \(int): must be between 1 and \(filteredFiles.count).".terminalColorize(.red))
        }
        
        let index = int - 1
        
        self.browseToSnapshot(index: index)
        
        return .loop("Opening folder \(filteredFiles[index].folder)...".terminalColorize(.magenta))
    }
    
    private func showSnapshotFiles(in pages: Pages) {
        let provider = makeSnapshotPagesProvider()
        
        pages.displayPages(withProvider: provider)
    }
    
    private func makeSnapshotPages(from files: [SnapshotFile]) -> Pages {
        let config = Pages.PageDisplayConfiguration(commandHandler: self)
        
        let pages = console.makePages(configuration: config)
        
        return pages
    }
    
    private func makeSnapshotPagesProvider() -> AnyConsoleDataProvider {
        let provider =
            MainMenu.makeSnapshotPagesProvider(
                from: filteredFiles,
                activeFilter: activeFilter)
        
        return provider
    }
    
    private static func makeSnapshotPagesProvider(from files: [SnapshotFile],
                                                  activeFilter: String?) -> AnyConsoleDataProvider {
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        formatter.doesRelativeDateFormatting = true
        
        let count = files.isEmpty ? 1 : files.count
        let header = "Snapshot files found - most recent first:"
        
        let provider = AnyConsoleDataProvider(count: count, header: header) { index in
            if files.isEmpty {
                if let activeFilter = activeFilter {
                    return [
                        "\("No snapshots found matching filter".terminalColorize(.red)) \(activeFilter.terminalColorize(.magenta))\(".".terminalColorize(.red))"
                    ]
                }
                
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
    
    private static func makeHelpString() -> String {
        return """
            Available commands and functionalities:

            \("quit".terminalColorize(.magenta)), \("q".terminalColorize(.magenta))
            Quits program.
            Entering '0' or hitting enter with an empty text also quits the program.

            \("<number>".terminalColorize(.magenta))
            = Navigate to snapshot file
                Navigates to the snapshot file at the given index using Finder.

            \("refresh".terminalColorize(.magenta)), \("r".terminalColorize(.magenta))
            = Refresh files
                Reloads snapshot files list by reloading the list from disk.

            \("filter [<pattern>]".terminalColorize(.magenta)), \("f [<pattern>]".terminalColorize(.magenta))
            = Filter files
                Uses a given \("<pattern>".terminalColorize(.magenta)) to filter files being displayed.
                Inserting an empty pattern clears filters back to default again.
                Refreshing or erasing files clears filters.
                Erase command ignores filtering (see \("<eraseall>".terminalColorize(.magenta))).
                Filtering is case-insensitive.
                Supports wildcards in paths, e.g. \("'MyView*'".terminalColorize(.blue)) matches \("'MyView'".terminalColorize(.blue)),
                    \("'MyViewController'".terminalColorize(.blue)), \("'MyViewModel'".terminalColorize(.blue)), etc.

            \("eraseall".terminalColorize(.magenta)), \("e".terminalColorize(.magenta))
            = Delete files
                \("Deletes".terminalColorize(.red)) all snapshot files on disk.
                Prompts for confirmation beforehands.
                Note: Does a lookup on disk prior to deletion, removing all snapshot
                      files found while ignoring any currently active filtering.

            \("help".terminalColorize(.magenta)), \("h".terminalColorize(.magenta))
            Displays this help prompt.

            """
    }
}

extension MainMenu: PagesCommandHandler {
    
    var commandPrompt: String? {
        if let activeFilter = activeFilter {
            return """
                \("Displaying entries matching".terminalColorize(.magenta)) \(activeFilter.terminalColorize(.blue))
                Specify an entry number to open its containing folder
                Type \("help".terminalColorize(.green)) to see reference for available commands.
                """
        }
        
        return """
            Specify an entry number to open its containing folder
            Type \("help".terminalColorize(.green)) to see reference for available commands.
            """
    }
    
    var acceptsCommands: Bool {
        return true
    }
    
    var canHandleEmptyInput: Bool {
        return activeFilter != nil
    }
    
    func executeCommand(_ input: String) throws -> Pages.PagesCommandResult {
        return processUserInputOnPages(input)
    }
    
}

private extension String {
    func matches(_ str: String...) -> Bool {
        return str.contains(self)
    }
}
