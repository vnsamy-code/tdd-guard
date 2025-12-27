import XCTest
@testable import Calculator

class CalculatorTests: TDDGuardTestCase {
    func testAddition() {
        let calculator = Calculator()
        XCTAssertEqual(calculator.add(2, 3), 5)
    }

    func testSubtraction() {
        let calculator = Calculator()
        XCTAssertEqual(calculator.subtract(5, 3), 2)
    }
}
