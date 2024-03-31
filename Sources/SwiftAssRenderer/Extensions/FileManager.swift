import Foundation

protocol FileManagerType {
    var documentsURL: URL { get }

    func fileExists(at path: URL) -> Bool
    func directoryExists(at path: URL) -> Bool
    func createDirectory(at path: URL) throws
    func removeItem(at path: URL) throws
    func createItem(at path: URL, contents: String, override: Bool) throws
}

extension FileManager: FileManagerType {
    var documentsURL: URL {
        URL.documentsDirectory
    }

    func fileExists(at path: URL) -> Bool {
        let exists = itemExists(at: path)
        return exists.exists && !exists.isDirectory
    }

    func directoryExists(at path: URL) -> Bool {
        let exists = itemExists(at: path)
        return exists.exists && exists.isDirectory
    }

    func itemExists(at path: URL) -> (exists: Bool, isDirectory: Bool) {
        var isDirectory: ObjCBool = true
        let fileExists = fileExists(atPath: path.path, isDirectory: &isDirectory)

        return (fileExists, isDirectory.boolValue)
    }

    func createDirectory(at path: URL) throws {
        try createDirectory(at: path, withIntermediateDirectories: true)
    }

    func createItem(at path: URL, contents: String, override: Bool) throws {
        if fileExists(at: path) {
            if override {
                try removeItem(at: path)
            } else {
                return
            }
        }
        try contents.write(toFile: path.path, atomically: true, encoding: .utf8)
    }
}
