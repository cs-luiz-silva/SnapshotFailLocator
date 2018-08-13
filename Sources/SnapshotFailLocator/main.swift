import Foundation
import Console

func main() {
    let console = Console()
    console.eraseScrollback = false
    
    let repository = SnapshotRepository()
    let mainMenu = MainMenu(console: console, repository: repository)
    
    console.startAlternativeScreenBuffer()
    
    console.clearScreen()
    
    mainMenu.run()
    
    console.stopAlternativeScreenBuffer()
}

main()
