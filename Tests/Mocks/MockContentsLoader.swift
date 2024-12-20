import Foundation
import Combine
@testable import SwiftAssRenderer

final class MockContentsLoader: ContentsLoaderType {
    let loadContentsFunc = FuncCheck<URL>()
    nonisolated(unsafe) var loadContentsStub: AnyPublisher<String?, Error> = Just(nil)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    func loadContents(from url: URL) -> AnyPublisher<String?, Error> {
        loadContentsFunc.call(url)
        return loadContentsStub
    }
}
