import XCTest
@testable import Calculator

class CalculatorTests: XCTestCase {
    func testShouldAddNumbersCorrectly() {
        let calc = Calculator()
        XCTAssertEqual(calc.add(2, 3), 6) // intentional failure
    }
}
