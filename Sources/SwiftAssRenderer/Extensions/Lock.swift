import Foundation

func withLock<T>(_ lock: NSLock, _ perform: () throws -> T) rethrows -> T {
    lock.lock()
    defer { lock.unlock() }
    return try perform()
}
