import XCTest
import SnapshotFailLocatorLib

class SnapshotRepositoryTests: XCTestCase {
    var sut: SnapshotRepository!
    var mockFileManager: MockFileManager!
    var mockSearchPath: MockSearchPathController!

    override func setUp() {
        super.setUp()
        mockSearchPath = MockSearchPathController()
        mockFileManager = MockFileManager()
        sut = SnapshotRepository(searchPathControllers: [mockSearchPath],
                                 fileManager: mockFileManager)
    }

    func testInit() {
        XCTAssertEqual(sut.searchPathControllers.count, 1)
        XCTAssert(sut.searchPathControllers[0] as? MockSearchPathController === mockSearchPath)
    }

    func testReloadFromDisk() {
        mockSearchPath.addMockFile(testName: "view")

        sut.reloadFromDisk()

        XCTAssertEqual(sut.files, mockSearchPath.snapshotFiles)
    }

    func testEraseFileAtIndex() throws {
        mockSearchPath.addMockFile(testName: "view1", date: Date().addingTimeInterval(-10))
        mockSearchPath.addMockFile(testName: "view2", date: Date())
        sut.reloadFromDisk()

        try sut.eraseFile(index: 1)

        assertRemovedFile(mockSearchPath.snapshotFiles[0])
        XCTAssertEqual(mockFileManager.didCallRemoveItem.count, 3)
    }

    func testEraseFiles() throws {
        mockSearchPath.addMockFile(testName: "view1")
        mockSearchPath.addMockFile(testName: "view2")
        sut.reloadFromDisk()

        try sut.eraseFiles()

        assertRemovedAllFiles()
    }

    func assertRemovedAllFiles(line: Int = #line) {
        for file in mockSearchPath.snapshotFiles {
            assertRemovedFile(file, line: line)
        }
    }

    func assertRemovedFile(_ snapshotFile: SnapshotFile, line: Int = #line) {
        assertRemovedFile(at: snapshotFile.diffPath, line: line)
        assertRemovedFile(at: snapshotFile.failurePath, line: line)
        assertRemovedFile(at: snapshotFile.referencePath, line: line)
    }

    func assertRemovedFile(at url: URL, line: Int = #line) {
        if !mockFileManager.didCallRemoveItem.contains(url) {
            recordFailure(withDescription: "Faild to remove file \(url)",
                          inFile: #file,
                          atLine: line,
                          expected: true)
        }
    }
}
