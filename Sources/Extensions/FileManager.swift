import Foundation

protocol FileManagerType {
    var documentsURL: URL { get }

    func directoryExists(at path: URL) -> Bool
    func createDirectory(at path: URL) throws
}

extension FileManager: FileManagerType {
    var documentsURL: URL {
        URL.documentsDirectory
    }

    func directoryExists(at path: URL) -> Bool {
        var isDirectory: ObjCBool = true
        let fileExists = fileExists(atPath: path.path, isDirectory: &isDirectory)

        return fileExists && isDirectory.boolValue
    }

    func createDirectory(at path: URL) throws {
        try createDirectory(at: path, withIntermediateDirectories: true)
    }
}
