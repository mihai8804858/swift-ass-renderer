final class FuncCheck<Argument>: Sendable {
    nonisolated(unsafe) var argument: Argument?
    nonisolated(unsafe) var arguments: [Argument] = []
    var wasCalled: Bool { argument != nil }

    func call(_ argument: Argument) {
        self.argument = argument
    }

    func reset() {
        argument = nil
        arguments = []
    }
}

extension FuncCheck where Argument == Void {
    func call() {
        call(())
    }
}

extension FuncCheck where Argument: Equatable {
    func wasCalled(with argument: Argument) -> Bool {
        wasCalled && self.argument == argument
    }
}
