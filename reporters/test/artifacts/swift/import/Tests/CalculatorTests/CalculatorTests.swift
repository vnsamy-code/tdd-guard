import XCTest
@testable import Calculator
// This import will cause a compilation error
@testable import NonExistentModule

class CalculatorTests: TDDGuardTestCase {
    func testAddition() {
        let calculator = Calculator()
        XCTAssertEqual(calculator.add(2, 3), 5)
    }
}
