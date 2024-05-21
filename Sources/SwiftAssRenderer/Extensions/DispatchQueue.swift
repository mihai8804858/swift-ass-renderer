import Dispatch
import Foundation

protocol DispatchQueueType {
    func executeAsync(_ work: @escaping () -> Void)
}

extension DispatchQueue: DispatchQueueType {
    func executeAsync(_ work: @escaping () -> Void) {
        async(execute: work)
    }
}

func UI(_ perform: @escaping () -> Void) {
    if Thread.isMainThread { return perform() }
    DispatchQueue.main.async(execute: perform)
}
