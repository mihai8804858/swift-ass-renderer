import Foundation
@testable import SwiftAssRenderer

final class MockFontConfig: FontConfigType {
    let configureFunc = FuncCheck<(OpaquePointer, OpaquePointer)>()
    func configure(library: OpaquePointer, renderer: OpaquePointer) throws {
        configureFunc.call((library, renderer))
    }
}
