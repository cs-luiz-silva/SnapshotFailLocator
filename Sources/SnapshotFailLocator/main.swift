import Console

func main() {
    let console = Console()
    
    let repository = SnapshotRepository()
    let mainMenu = MainMenu(console: console, repository: repository)
    
    mainMenu.run()
}

main()
