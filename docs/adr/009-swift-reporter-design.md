# ADR-009: Swift Reporter Design

## Status

In Progress

## Context

Design exploration for `tdd-guard-swift`, a compiled binary reporter supporting XCTest and Swift Testing frameworks.

## Design Questions & Decisions

### Single binary vs separate binaries for XCTest and Swift Testing

One binary handles both frameworks. All three parsers (XCTest, Swift Testing, Compilation) run simultaneously on every line — each silently ignores lines it doesn't recognise. Results are merged at the end. CompilationErrorParser activates only if zero tests were collected and errors were found.

### Framework detection strategy

The original plan buffered all stdin then detected the framework from signal lines. Considered alternatives: line-1 streaming detection (fires immediately for `swift test`), file import scanning (rejected — unreliable for mixed projects), project config file (deferred — adds config surface for a problem auto-detection already solves), environment variable (equivalent to the `--framework` flag).

All detection approaches break down when a single file imports both `XCTest` and `Testing` — the output stream is interleaved and routing to one parser drops the other's events. Running all parsers simultaneously eliminates the detection phase entirely, handles mixed files naturally, and simplifies the architecture.

### iOS vs macOS invocation patterns

macOS SPM projects use `swift test 2>&1 | tdd-guard-swift`. iOS projects must use `xcodebuild test -destination 'platform=iOS Simulator,...' 2>&1 | tdd-guard-swift` because iOS requires a simulator. The xcodebuild output is verbose but harmless — parsers only act on lines matching their specific patterns.

### Scope: which test frameworks are supported

XCTest and Swift Testing are the two official Apple frameworks and are the initial scope. Third-party frameworks (Quick/Nimble) are deferred until both official frameworks are shipped and stable.

### Installation model: plugin vs binary pipe

Swift has no stable third-party reporter plugin API (unlike RSpec formatters or Jest reporters). XCTestObservation requires observers to be compiled into the test bundle, making a plugin model impractical. The binary pipe model (same as Go and Rust reporters) is the only viable approach.
