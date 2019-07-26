import Foundation
import SnapshotFailLocatorLib

class MockSearchPathController: SearchPathController {
    var name: String
    var baseUrl: URL
    var snapshotFiles: [SnapshotFile] = []

    init(name: String = "Mock Search Path",
         baseUrl: URL = URL(fileURLWithPath: "/snapshots/")) {

        self.name = name
        self.baseUrl = baseUrl
    }

    func addMockFile(testName: String, date: Date = Date()) {
        let failurePath = baseUrl.appendingPathComponent("failed_\(testName)")
        let referencePath = baseUrl.appendingPathComponent("reference_\(testName)")
        let diffPath = baseUrl.appendingPathComponent("diff_\(testName)")

        let snapshotFile = SnapshotFile(failurePath: failurePath, referencePath: referencePath, diffPath: diffPath, folder: baseUrl.path, changeDate: date)

        addMockFile(snapshotFile)
    }

    func addMockFile(_ file: SnapshotFile) {
        snapshotFiles.append(file)
    }

    func enumerateSnapshotFiles() -> AnySequence<SnapshotFile> {
        return AnySequence(snapshotFiles)
    }
}
