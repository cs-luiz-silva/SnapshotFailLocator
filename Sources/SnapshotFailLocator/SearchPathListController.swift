import Foundation

/// Controls access to the underlying search path list, saved as a
/// snapshot-paths.json file at the app's launch path.
class SearchPathListController {
    var configFileName: String = "snapshot-paths.json"
    var pathForConfigurationFile: URL {
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(configFileName)
    }

    init() {

    }

    /// Reloads search path controllers from disk
    func loadSearchPathControllers() throws -> [SearchPathController] {
        if !FileManager.default.fileExists(atPath: pathForConfigurationFile.path) {
            return [DerivedDataSearchPathController()]
        }

        let data = try Data(contentsOf: pathForConfigurationFile)
        let decoder = JSONDecoder()
        let config = try decoder.decode(SnapshotConfigurationFile.self, from: data)

        return config.searchPaths.map(snapshotPathController(for:))
    }

    private func snapshotPathController(for searchPath: SnapshotSearchPath) -> SearchPathController {
        return CustomSearchPathController(url: searchPath.path)
    }
}
