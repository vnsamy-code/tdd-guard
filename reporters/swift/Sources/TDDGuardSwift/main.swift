import ArgumentParser
import Foundation

struct TDDGuardSwift: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "tdd-guard-swift",
        abstract: "TDD Guard reporter for Swift test runners. Pipe swift test or xcodebuild output through this binary."
    )

    @Option(name: .long, help: "Absolute path to project root (default: $TDD_GUARD_PROJECT_ROOT or $PWD)")
    var projectRoot: String?

    func run() throws {
        let root = projectRoot
            ?? ProcessInfo.processInfo.environment["TDD_GUARD_PROJECT_ROOT"]
            ?? FileManager.default.currentDirectoryPath

        let xcTestParser = XCTestParser()
        let swiftTestingParser = SwiftTestingParser()
        let compilationParser = CompilationErrorParser()

        // Single pass: passthrough to stdout while all parsers process each line simultaneously
        while let line = readLine() {
            print(line)
            xcTestParser.process(line: line)
            swiftTestingParser.process(line: line)
            compilationParser.process(line: line)
        }

        // Merge results — compilation only activates if no tests were collected
        var allTests = xcTestParser.results + swiftTestingParser.results
        if allTests.isEmpty {
            allTests = compilationParser.results
        }

        let output = Transformer.transform(allTests)
        try Storage(projectRoot: root).save(output)
    }
}

TDDGuardSwift.main()
