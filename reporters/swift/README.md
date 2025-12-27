# TDD Guard - Swift XCTest Reporter

Captures XCTest results for TDD Guard enforcement on iOS, macOS, and Linux platforms.

## Overview

The Swift reporter uses XCTest's `XCTestObservation` protocol to capture test results in real-time and save them in a format that TDD Guard can validate. This enables AI-powered TDD enforcement for Swift projects.

## Installation

### Swift Package Manager

Add TDD Guard to your package dependencies:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/nizos/tdd-guard", from: "1.0.0")
]
```

Then add the reporter to your test target:

```swift
targets: [
    .testTarget(
        name: "YourAppTests",
        dependencies: [
            "YourApp",
            .product(name: "TDDGuardXCTest", package: "tdd-guard")
        ]
    )
]
```

## Configuration

### Step 1: Create Observer Bootstrap

Create a file in your test target to register the observer:

```swift
// Tests/YourAppTests/TestObserverBootstrap.swift
import XCTest
import TDDGuardXCTest

@objc(TestObserverBootstrap)
class TestObserverBootstrap: NSObject {
    override init() {
        super.init()

        // Get project root from environment or use current directory
        let projectRoot = ProcessInfo.processInfo.environment["PROJECT_ROOT"]
            ?? FileManager.default.currentDirectoryPath

        let observer = TDDGuardObserver(projectRoot: projectRoot)
        XCTestObservationCenter.shared.addTestObserver(observer)
    }
}
```

### Step 2: Platform-Specific Setup

#### iOS / macOS (Xcode Projects)

Configure the test bundle's principal class in `Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).TestObserverBootstrap</string>
</dict>
</plist>
```

**Note:** Xcode automatically creates `Info.plist` for test targets. If it doesn't exist, create it in your test target directory.

#### Linux / Swift Package Manager

For command-line Swift packages, use `XCTMain` with observers (Swift 5.4+):

```swift
// Tests/LinuxMain.swift
import XCTest
import TDDGuardXCTest

let projectRoot = ProcessInfo.processInfo.environment["PROJECT_ROOT"]
    ?? FileManager.default.currentDirectoryPath

let observer = TDDGuardObserver(projectRoot: projectRoot)
XCTMain(observers: [observer])
```

## Usage

Once configured, the reporter automatically captures test results whenever you run tests:

```bash
# Swift Package Manager
swift test

# Xcode (Command Line)
xcodebuild test -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone 15'

# Xcode IDE
# Cmd+U or Product > Test
```

### Output Location

Test results are saved to:

```
.claude/tdd-guard/data/test.json
```

### Example Output

```json
{
  "testModules": [
    {
      "moduleId": "UserAuthenticationTests",
      "tests": [
        {
          "name": "testLoginSuccess",
          "fullName": "UserAuthenticationTests.testLoginSuccess",
          "state": "passed"
        },
        {
          "name": "testLoginFailure",
          "fullName": "UserAuthenticationTests.testLoginFailure",
          "state": "failed",
          "errors": [
            {
              "message": "XCTAssertEqual failed: (\"error\") is not equal to (\"success\")",
              "stack": "/Users/dev/MyApp/Tests/UserAuthenticationTests.swift:42"
            }
          ]
        }
      ]
    }
  ],
  "reason": "failed"
}
```

## TDD Guard Integration

With TDD Guard hook enabled in Claude Code, the workflow becomes:

1. **Write a failing test**
2. **Run tests** - Reporter captures results
3. **Claude Code attempts to write implementation**
4. **TDD Guard validates** - Checks test results before allowing changes
5. **Blocks non-compliant changes** - Ensures you follow TDD

Claude Code will automatically:

- ✅ Read test results when editing files
- ✅ Validate TDD compliance using AI
- ✅ Block changes that skip tests or over-implement
- ✅ Provide guidance on TDD violations

## Configuration Options

### Custom Project Root

If your tests run from a different directory than your project root:

```swift
let observer = TDDGuardObserver(projectRoot: "/absolute/path/to/project")
```

### Environment Variable

Set the project root via environment variable:

```bash
export PROJECT_ROOT=/path/to/project
swift test
```

The reporter checks in this order:

1. `projectRoot` parameter
2. `PROJECT_ROOT` environment variable
3. Current working directory

## Platform Support

| Platform | Supported | Notes      |
| -------- | --------- | ---------- |
| macOS    | ✅        | macOS 13+  |
| iOS      | ✅        | iOS 16+    |
| Linux    | ✅        | Swift 5.9+ |
| watchOS  | ⚠️        | Not tested |
| tvOS     | ⚠️        | Not tested |

## Troubleshooting

### Observer Not Running

**Symptom:** No `test.json` file is created after running tests.

**Solutions:**

- Verify `NSPrincipalClass` is set in test target's `Info.plist` (iOS/macOS)
- Check that `TestObserverBootstrap` is in the correct test target
- Ensure the class is `@objc` and inherits from `NSObject`
- For Linux, verify you're using `XCTMain` with the observer

### Wrong Project Root

**Symptom:** `test.json` file is created in the wrong location.

**Solutions:**

- Pass explicit `projectRoot` to `TDDGuardObserver`
- Set `PROJECT_ROOT` environment variable
- Check current working directory when tests run

### Compilation Errors Not Captured

**Symptom:** Build fails but no test results are saved.

**Note:** XCTestObservation only captures test execution. Compilation errors prevent tests from running, so the observer never executes. TDD Guard handles this by detecting missing test results.

## Advanced Usage

### Custom Storage

For testing or custom integrations, provide a custom storage implementation:

```swift
class CustomStorage: Storage {
    func saveTest(_ content: String) async throws {
        // Your custom storage logic
    }
}

let storage = CustomStorage()
let observer = TDDGuardObserver(storage: storage)
```

## Contributing

Found a bug or want to contribute? Visit the [main repository](https://github.com/nizos/tdd-guard).

## License

Same as TDD Guard main package.
