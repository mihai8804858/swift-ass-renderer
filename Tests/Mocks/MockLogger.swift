@testable import SwiftAssRenderer

final class MockLogger: LoggerType {
    let configureLibraryFunc = FuncCheck<(LibraryWrapperType.Type, OpaquePointer)>()
    func configureLibrary(_ wrapper: LibraryWrapperType.Type, library: OpaquePointer) {
        configureLibraryFunc.call((wrapper, library))
    }

    let logFunc = FuncCheck<(String, LogLevel)>()
    func log(message: String, messageLevel: LogLevel) {
        logFunc.call((message, messageLevel))
    }
}
