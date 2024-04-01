func == <each T: Equatable>(lhs: (repeat each T), rhs: (repeat each T)) -> Bool {
    func throwIfNotEqual<U: Equatable>(_ lhs: U, _ rhs: U) throws {
        guard lhs == rhs else { throw CancellationError() }
    }

    do {
        repeat try throwIfNotEqual(each lhs, each rhs)
    } catch {
        return false
    }

    return true
}
