import Foundation
@testable import SwiftAssRenderer

final class MockFileManager: FileManagerType {
    var documentsURL: URL = .documentsDirectory

    let directoryExistsFunc = FuncCheck<URL>()
    var directoryExistsStub = false
    func directoryExists(at path: URL) -> Bool {
        directoryExistsFunc.call(path)
        return directoryExistsStub
    }

    let createDirectoryFunc = FuncCheck<URL>()
    func createDirectory(at path: URL) throws {
        createDirectoryFunc.call(path)
    }
}
