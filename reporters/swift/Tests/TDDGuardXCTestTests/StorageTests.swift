import XCTest
@testable import TDDGuardXCTest

final class StorageTests: XCTestCase {

    // MARK: - MemoryStorage Tests

    func testMemoryStorageSavesData() async throws {
        let storage = MemoryStorage()
        let testData = "test data"

        try await storage.saveTest(testData)

        XCTAssertEqual(storage.getTest(), testData)
    }

    func testMemoryStorageClearsData() async throws {
        let storage = MemoryStorage()
        try await storage.saveTest("test data")

        storage.clear()

        XCTAssertNil(storage.getTest())
    }

    // MARK: - FileStorage Tests

    func testFileStorageInitWithProjectRoot() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .path

        let storage = FileStorage(projectRoot: tempDir)
        XCTAssertNotNil(storage)
    }

    func testFileStorageInitWithoutProjectRoot() {
        let storage = FileStorage()
        XCTAssertNotNil(storage)
    }

    func testFileStorageCreatesDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let tempPath = tempDir.path

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let storage = FileStorage(projectRoot: tempPath)
        try await storage.saveTest("test data")

        // Verify directory structure was created
        let dataDir = tempDir
            .appendingPathComponent(".claude")
            .appendingPathComponent("tdd-guard")
            .appendingPathComponent("data")

        XCTAssertTrue(FileManager.default.fileExists(atPath: dataDir.path))
    }

    func testFileStorageSavesTestData() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let tempPath = tempDir.path

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let storage = FileStorage(projectRoot: tempPath)
        let testData = #"{"testModules":[],"reason":"passed"}"#

        try await storage.saveTest(testData)

        // Verify file was created and contains correct data
        let testFilePath = tempDir
            .appendingPathComponent(".claude/tdd-guard/data/test.json")

        XCTAssertTrue(FileManager.default.fileExists(atPath: testFilePath.path))

        let savedData = try String(contentsOf: testFilePath, encoding: .utf8)
        XCTAssertEqual(savedData, testData)
    }

    func testFileStorageOverwritesExistingData() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let tempPath = tempDir.path

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let storage = FileStorage(projectRoot: tempPath)

        // Save first data
        try await storage.saveTest("first data")

        // Save second data (should overwrite)
        try await storage.saveTest("second data")

        // Verify only second data exists
        let testFilePath = tempDir
            .appendingPathComponent(".claude/tdd-guard/data/test.json")

        let savedData = try String(contentsOf: testFilePath, encoding: .utf8)
        XCTAssertEqual(savedData, "second data")
    }
}
