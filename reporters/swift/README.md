# TDD Guard Swift Reporter

Swift reporter that captures test results for TDD Guard validation.

## Requirements

- Swift 5.9+
- macOS 13+ (or Linux with swift-corelibs-foundation)
- [TDD Guard](https://github.com/nizos/tdd-guard) installed globally

## Installation

```bash
# Build
cd reporters/swift
swift build -c release

# Install
sudo cp .build/release/tdd-guard-swift /usr/local/bin/

# Linux (portable static binary, no Swift runtime dependency)
swift build -c release --static-swift-stdlib
sudo cp .build/release/tdd-guard-swift /usr/local/bin/
```

## Usage

Pipe `swift test` or `xcodebuild` output through the reporter:

```bash
# macOS SPM — XCTest or Swift Testing
swift test 2>&1 | tdd-guard-swift --project-root /absolute/path/to/project

# macOS SPM — Swift Testing event stream
swift test --event-stream-output-path - 2>&1 | tdd-guard-swift --project-root /absolute/path/to/project

# iOS / xcodebuild
xcodebuild test \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  2>&1 | tdd-guard-swift --project-root /absolute/path/to/project
```

## Configuration

### Project Root

The `--project-root` flag must be an absolute path. Falls back to the `TDD_GUARD_PROJECT_ROOT` environment variable, then `$PWD`.

### Claude Code Hook

Add to `.claude/settings.json` in your project:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "swift test 2>&1 | tdd-guard-swift --project-root $PWD"
          }
        ]
      }
    ]
  }
}
```

For `xcodebuild` projects, replace the command with the appropriate `xcodebuild test` invocation.

## How It Works

The reporter:

1. Reads test runner output from stdin
2. Passes it through to stdout unchanged
3. Runs XCTestParser, SwiftTestingParser, and CompilationErrorParser simultaneously on each line
4. Writes normalised results to `.claude/tdd-guard/data/test.json`

All three parsers run on every line — no framework detection required. This handles projects that mix XCTest and Swift Testing in the same test target naturally.

## Supported Frameworks

- **XCTest** — class-based, all Apple platforms and Linux via SPM
- **Swift Testing** — macro-based, Swift 5.9+ (`import Testing`)
- **Compilation errors** — synthetic `compilation/build` test when no tests run due to build failure

Third-party frameworks (Quick/Nimble) are not supported in this version.

## License

MIT
