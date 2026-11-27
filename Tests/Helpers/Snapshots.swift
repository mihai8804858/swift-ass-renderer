import Foundation
import Testing
import SnapshotTesting

func platformName() -> String {
    #if targetEnvironment(macCatalyst)
    "maccatalyst"
    #elseif os(iOS)
    "ios"
    #elseif os(tvOS)
    "tvos"
    #elseif os(macOS)
    "macos"
    #elseif os(visionOS)
    "visionos"
    #endif
}

func snapshotsDirectory(file: StaticString = #filePath, pathComponents: String...) -> URL {
    let fileURL = URL(fileURLWithPath: "\(file)", isDirectory: false)
    let fileName = fileURL.deletingPathExtension().lastPathComponent
    let snapshotsDirectory = fileURL
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(fileName)

    return pathComponents.reduce(snapshotsDirectory) { $0.appendingPathComponent($1) }
}

func assertSnapshot<Value, Format>(
    of value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    snapshotDirectory: URL? = nil,
    record recording: Bool = false,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let failure = verifySnapshot(
        of: try value(),
        as: snapshotting,
        named: name,
        record: recording,
        snapshotDirectory: snapshotDirectory?.path,
        fileID: fileID,
        file: filePath,
        testName: testName,
        line: line,
        column: column
    )
    guard let message = failure else { return }
    Issue.record(
        Comment(rawValue: message),
        sourceLocation: SourceLocation(
            fileID: "\(fileID)",
            filePath: "\(filePath)",
            line: Int(line),
            column: Int(column)
        )
    )
}
