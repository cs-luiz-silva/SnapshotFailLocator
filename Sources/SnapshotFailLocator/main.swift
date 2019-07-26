import Foundation
import Console
import SnapshotFailLocatorLib

func main() {
    let console = Console()
    console.eraseScrollback = false

    let listController = SearchPathListController()
    let searchPathControllers: [SearchPathController]
    do {
        searchPathControllers = try listController.loadSearchPathControllers()
    } catch {
        searchPathControllers = [DerivedDataSearchPathController()]

        console.printLine("Error loading config file at \(listController.pathForConfigurationFile.path): \(error)".terminalColorize(.yellow))
        console.printLine("Defaulting to derived data search path".terminalColorize(.yellow))
        _ = console.readLineWith(prompt: "Press [ENTER] to continue")
    }
    
    let repository = SnapshotRepository(searchPathControllers: searchPathControllers,
                                        fileManager: FileManager.default)
    let mainMenu = MainMenu(console: console, repository: repository)
    
    console.startAlternativeScreenBuffer()
    
    console.clearScreen()
    
    mainMenu.run()
    
    console.stopAlternativeScreenBuffer()
}

main()
