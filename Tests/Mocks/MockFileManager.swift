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

    let fileExistsFunc = FuncCheck<URL>()
    var fileExistsStub = false
    func fileExists(at path: URL) -> Bool {
        fileExistsFunc.call(path)
        return fileExistsStub
    }

    let createDirectoryFunc = FuncCheck<URL>()
    func createDirectory(at path: URL) throws {
        createDirectoryFunc.call(path)
    }

    let removeItemFunc = FuncCheck<URL>()
    func removeItem(at path: URL) throws {
        removeItemFunc.call(path)
    }

    // swiftlint:disable:next large_tuple
    let createItemFunc = FuncCheck<(URL, String, Bool)>()
    func createItem(at path: URL, contents: String, override: Bool) throws {
        createItemFunc.call((path, contents, override))
    }
}
