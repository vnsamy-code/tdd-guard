import NonExistentModule // intentional compilation error

public struct Calculator {
    public init() {}
    public func add(_ a: Int, _ b: Int) -> Int { a + b }
}
