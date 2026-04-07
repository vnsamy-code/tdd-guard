import Foundation

struct Storage {
    let projectRoot: String

    func save(_ output: TDDGuardOutput) throws {
        let dataDir = URL(fileURLWithPath: projectRoot)
            .appendingPathComponent(".claude/tdd-guard/data", isDirectory: true)
        let fileURL = dataDir.appendingPathComponent("test.json")
        let tmpURL = dataDir.appendingPathComponent("test.json.tmp")

        try FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(output)
        try data.write(to: tmpURL)

        try? FileManager.default.removeItem(at: fileURL)
        try FileManager.default.moveItem(at: tmpURL, to: fileURL)
    }
}
