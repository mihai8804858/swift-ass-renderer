@testable import SwiftAssRenderer

final class MockLogger: LoggerType {
    let configureLibraryFunc = FuncCheck<(LibraryWrapperType.Type, OpaquePointer)>()
    func configureLibrary(_ wrapper: LibraryWrapperType.Type, library: OpaquePointer) {
        configureLibraryFunc.call((wrapper, library))
    }

    let logFunc = FuncCheck<LogMessage>()
    func log(message: LogMessage) {
        logFunc.call(message)
    }
}
