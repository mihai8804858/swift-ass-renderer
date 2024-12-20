import Dispatch
import Foundation

protocol DispatchQueueType: Sendable {
    func executeAsync(_ work: @escaping @Sendable () -> Void)
}

extension DispatchQueue: DispatchQueueType {
    func executeAsync(_ work: @escaping @Sendable () -> Void) {
        async(execute: work)
    }
}
