/// Describes a controller for searching into paths looking for snapshot failures
protocol SearchPathController {
    /// A display name for this search path controller
    var name: String { get }

    /// Requests an iterator for listing through all snapshot files from this
    /// search path controller
    func enumerateSnapshotFiles() -> AnySequence<SnapshotFile>
}
