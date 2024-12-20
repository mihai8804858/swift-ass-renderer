import Foundation
@testable import SwiftAssRenderer

final class MockBundle: BundleType {
    let urlFunc = FuncCheck<(String?, String?)>()
    nonisolated(unsafe) var urlStub: URL?
    func url(forResource name: String?, withExtension ext: String?) -> URL? {
        urlFunc.call((name, ext))
        return urlStub
    }
}
