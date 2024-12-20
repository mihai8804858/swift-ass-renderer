import Foundation
@testable import SwiftAssRenderer

final class MockFileManager: FileManagerType {
    nonisolated(unsafe) var cachesDirectory: URL = {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, *) {
            URL.cachesDirectory
        } else {
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        }
    }()

    let directoryExistsFunc = FuncCheck<URL>()
    nonisolated(unsafe) var directoryExistsStub = false
    func directoryExists(at path: URL) -> Bool {
        directoryExistsFunc.call(path)
        return directoryExistsStub
    }

    let fileExistsFunc = FuncCheck<URL>()
    nonisolated(unsafe) var fileExistsStub = false
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

    let createItemFunc = FuncCheck<(URL, String, Bool)>()
    func createItem(at path: URL, contents: String, override: Bool) throws {
        createItemFunc.call((path, contents, override))
    }
}
