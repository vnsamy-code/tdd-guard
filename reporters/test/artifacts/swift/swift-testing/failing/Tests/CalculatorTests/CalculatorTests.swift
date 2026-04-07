import Testing
@testable import Calculator

@Suite struct CalculatorTests {
    @Test func testShouldAddNumbersCorrectly() {
        let calc = Calculator()
        #expect(calc.add(2, 3) == 6) // intentional failure
    }
}
