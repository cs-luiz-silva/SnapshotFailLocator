import Foundation

/// A command that can be issued to erase snapshot files found.
class EraseSnapshotsCommand {
    var settings: Settings
    
    init(settings: Settings) {
        self.settings = settings
    }
    
    func run() {
        
    }
}

extension EraseSnapshotsCommand {
    struct Settings {
        static var `default` = Settings()
        
        /// If non-nil, only removes snapshot files which predates `fromDate`.
        var fromDate: Date?
    }
}
