import XCTest
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

func snapshotsDirectory(file: StaticString = #file, pathComponents: String...) -> URL {
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
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    let failure = verifySnapshot(
        of: try value(),
        as: snapshotting,
        named: name,
        record: recording,
        snapshotDirectory: snapshotDirectory?.path,
        file: file,
        testName: testName,
        line: line
    )
    guard let message = failure else { return }
    XCTFail(message, file: file, line: line)
}
