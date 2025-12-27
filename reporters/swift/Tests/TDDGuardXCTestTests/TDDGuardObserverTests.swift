import XCTest
@testable import TDDGuardXCTest

final class TDDGuardObserverTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitWithProjectRoot() {
        let observer = TDDGuardObserver(projectRoot: "/custom/path")
        XCTAssertNotNil(observer)
    }

    func testInitWithCustomStorage() {
        let storage = MemoryStorage()
        let observer = TDDGuardObserver(storage: storage)
        XCTAssertNotNil(observer)
    }

    // NOTE: Full observer functionality is tested via integration tests
    // with real Swift packages, as mocking XCTestCase is complex
}
