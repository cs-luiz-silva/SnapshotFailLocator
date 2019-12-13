import Foundation
import Cocoa
import Console
import SnapshotFailLocatorLib

/// Manages displaying of snapshots from a snapshot repository into a paged list
/// with support for spawning of commands from CLI input.
class MainMenu {
    var console: ConsoleClient
    var repository: SnapshotRepository
    
    init(console: ConsoleClient, repository: SnapshotRepository) {
        self.console = console
        self.repository = repository
    }
    
    func run() {
        locateFiles(eraseFilter: true)
        
        let pages = makeSnapshotPages(from: repository.filteredFiles)
        showSnapshotFiles(in: pages)
    }
    
    func locateFiles(eraseFilter: Bool) {
        if eraseFilter {
            repository.activeFilter = nil
        }
        
        console.printLine("Locating files...")
        repository.reloadFromDisk()
    }
    
    // MARK: Functionalities
    
    private func browseToSnapshot(index: Int) {
        let file = repository.filteredFiles[index]
        
        NSWorkspace.shared
            .activateFileViewerSelecting([file.failurePath, file.diffPath, file.referencePath])
    }
    
    private func erase(index: Int) -> Bool {
        let path = (repository.filteredFiles[index].referencePath.absoluteString as NSString).lastPathComponent
        
        let prompt =
            console
                .readSureLineWith(prompt:
                    "\nAre you sure you want to \("delete".terminalColorize(Color.destructive)) snapshot file \(path.terminalColorize(Color.fileName)) and related files (yes/no)?")
        
        guard prompt.lowercased().matches("yes", "y") else {
            return false
        }
        
        // Erase all files
        console.printLine("Erasing \(path.terminalColorize(Color.fileName))...")
        
        do {
            try repository.eraseFile(index: index)
        } catch {
            console.printLine("Error erasing file: \(error)")
            _=console.readLineWith(prompt: "")
        }
        
        return true
    }
    
    private func eraseAll() -> Pages.PagesCommandResult {
        if repository.filteredFiles.isEmpty {
            return Pages.PagesCommandResult.loop("No files available to delete".terminalColorize(.blue))
        }
        
        let isFiltered: Bool
        let prompt: String
        
        if let filter = repository.activeFilter {
            isFiltered = true
            prompt = """
            
            Are you sure you want to \("delete".terminalColorize(Color.destructive)) all \
            \(repository.filteredFiles.count.description.terminalColorize(.blue)) \
            snapshot files matching current filter \(filter.terminalColorize(Color.filterString)) (yes/no)?
            """
        } else {
            isFiltered = false
            prompt = """
            
            Are you sure you want to \("delete".terminalColorize(Color.destructive)) all \
            \(repository.files.count.description.terminalColorize(.blue)) \
            snapshot files (yes/no)?
            """
        }
        
        guard console.readSureLineWith(prompt: prompt).lowercased().matches("yes", "y") else {
            return .loop(nil)
        }
        
        // Erase all files
        console.printLine("Erasing files...")
        
        do {
            if isFiltered {
                try repository.eraseDisplayedFiles()
            } else {
                try repository.eraseFiles()
            }
        } catch {
            console.printLine("Error erasing files: \(error)")
            _=console.readLineWith(prompt: "")
        }
        
        return .modifyList(keepPageIndex: false) { pages in
            self.locateFiles(eraseFilter: true)
            return self.makeSnapshotPagesProvider()
        }
    }
    
    private func processEraseAll(in input: String) -> Pages.PagesCommandResult? {
        let split =
            input
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: " ")
        
        if split.count == 1 {
            if !split[0].matches("erase", "e") {
                return nil
            }
            
            return eraseAll()
        }
        
        let eraseIndexString = split.dropFirst().joined(separator: " ")
        guard let eraseIndex = Int(eraseIndexString), eraseIndex > 0 && eraseIndex <= repository.filteredFiles.count else {
            return .loop("Invalid entry index '\(eraseIndexString)': expected an entry index from above.".terminalColorize(Color.destructive))
        }
        
        if erase(index: eraseIndex - 1) {
            return .modifyList(keepPageIndex: true) { pages in
                self.locateFiles(eraseFilter: false)
                return self.makeSnapshotPagesProvider()
            }
        }
        
        return .loop(nil)
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
            repository.activeFilter = nil
            
            return .modifyList(keepPageIndex: false) { _ in
                self.makeSnapshotPagesProvider()
            }
        }
        
        let filter = split.dropFirst().joined(separator: " ")
        
        if filter == repository.activeFilter {
            return .loop(nil)
        }
        
        if filter.isEmpty {
            // Empty string clears filters
            repository.activeFilter = nil
        } else {
            repository.activeFilter = filter
        }
        
        return .modifyList(keepPageIndex: false) { _ in
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
            if repository.activeFilter != nil {
                repository.activeFilter = nil
                
                return .modifyList(keepPageIndex: false) { _ in
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
            return .modifyList(keepPageIndex: true) { pages in
                self.locateFiles(eraseFilter: false)
                return self.makeSnapshotPagesProvider()
            }
        }
        
        // Filter files
        if input.hasPrefix("filter") || input.hasPrefix("f") {
            if let result = processFilter(in: input) {
                return result
            }
        }
        
        // Erase/erase all
        if input.hasPrefix("erase") || input.hasPrefix("e") {
            if let result = processEraseAll(in: input) {
                return result
            }
        }
        
        // Assume an entry integer is entered, then.
        guard let int = Int(input) else {
            return .loop("Invalid entry index '\(input)': expected an entry index from above.".terminalColorize(Color.destructive))
        }
        
        if repository.filteredFiles.isEmpty {
            return .loop("No snapshot files are available. Type 'refresh' to reload from disk now.".terminalColorize(Color.destructive))
        }
        
        if int < 1 || int > repository.filteredFiles.count {
            return .loop("Invalid entry index \(int): must be between 1 and \(repository.filteredFiles.count).".terminalColorize(Color.destructive))
        }
        
        let index = int - 1
        
        self.browseToSnapshot(index: index)
        
        return .loop("Opening folder \(repository.filteredFiles[index].folder) ...".terminalColorize(.magenta))
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
                from: repository.filteredFiles,
                activeFilter: repository.activeFilter)
        
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
                        """
                        \("No snapshots found matching filter".terminalColorize(Color.destructive)) \
                        \(activeFilter.terminalColorize(Color.filterString))\(".".terminalColorize(Color.destructive))
                        """
                    ]
                }
                
                return ["No snapshots available.".terminalColorize(Color.destructive)]
            }
            
            let file = files[index]
            
            let fileName = file.failurePath.lastPathComponent
            let dirPath =
                file.failurePath.pathComponents
                    .dropLast().suffix(1)
                    .joined(separator: "/")
                    .terminalColorize(.green)
            
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
                Erase command respects filtering (see \("<erase>".terminalColorize(.magenta))).
                Filtering is case-insensitive.
                Supports wildcards in paths, e.g. \("'MyView*'".terminalColorize(.blue)) matches \("'MyView'".terminalColorize(.blue)),
                    \("'MyViewController'".terminalColorize(.blue)), \("'MyViewModel'".terminalColorize(.blue)), etc.

            \("erase [<index>]".terminalColorize(.magenta)), \("e [<index>]".terminalColorize(.magenta))
            = Delete files
                \("Deletes".terminalColorize(Color.destructive)) all snapshot files on disk, or a specific snapshot
                from the list, in case the optional \("<index>".terminalColorize(.magenta)) is provided.
                Prompts for confirmation beforehands.
                Note: Removes files based on currently active filters; removing all files will respect active filters,
                too.

            \("help".terminalColorize(.magenta)), \("h".terminalColorize(.magenta))
            Displays this help prompt.

            """
    }
}

extension MainMenu: PagesCommandHandler {
    
    var commandPrompt: String? {
        if let activeFilter = repository.activeFilter {
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
        return repository.activeFilter != nil
    }
    
    func executeCommand(_ input: String) throws -> Pages.PagesCommandResult {
        return processUserInputOnPages(input)
    }
    
    private struct Color {
        static let filterString: ConsoleColor = .magenta
        static let destructive: ConsoleColor = .red
        static let fileName: ConsoleColor = .blue
        static let path: ConsoleColor = .magenta
    }
    
}

private extension String {
    func matches(_ str: String...) -> Bool {
        return str.contains(self)
    }
}
