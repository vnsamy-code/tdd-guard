import XCTest
@testable import Calculator

class CalculatorTests: TDDGuardTestCase {
    func testAddition() {
        let calculator = Calculator()
        // This test will fail
        XCTAssertEqual(calculator.add(2, 3), 6)
    }
}
