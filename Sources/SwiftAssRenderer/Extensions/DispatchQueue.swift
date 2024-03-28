import Dispatch

protocol DispatchQueueType {
    func executeAsync(_ work: @escaping () -> Void)
}

extension DispatchQueue: DispatchQueueType {
    func executeAsync(_ work: @escaping () -> Void) {
        async(execute: work)
    }
}
