import Foundation
@testable import SwiftAssRenderer

final class MockEnvironment: EnvironmentVariablesType {
    // swiftlint:disable:next large_tuple
    let setValueFunc = FuncCheck<(String, String, Bool)>()
    func setValue(_ value: String, forName name: String, override: Bool) {
        setValueFunc.call((value, name, override))
    }
}
