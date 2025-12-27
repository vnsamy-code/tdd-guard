import XCTest
import TDDGuardXCTest

/// Base test class that automatically registers TDDGuardObserver
/// All test classes should inherit from this instead of XCTestCase
open class TDDGuardTestCase: XCTestCase {
    private static var observerRegistered = false

    open override class func setUp() {
        super.setUp()

        // Register observer once
        if !observerRegistered {
            let projectRoot = ProcessInfo.processInfo.environment["CLAUDE_PROJECT_DIR"]
                ?? ProcessInfo.processInfo.environment["PWD"]
            let observer = TDDGuardObserver(projectRoot: projectRoot)
            XCTestObservationCenter.shared.addTestObserver(observer)
            observerRegistered = true
        }
    }
}
