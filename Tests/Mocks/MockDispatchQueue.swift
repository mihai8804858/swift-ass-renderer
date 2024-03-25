@testable import SwiftAssRenderer

final class MockDispatchQueue: DispatchQueueType {
    let executeAsyncFunc = FuncCheck<Void>()
    func executeAsync(_ work: @escaping () -> Void) {
        executeAsyncFunc.call()
        work()
    }
}
