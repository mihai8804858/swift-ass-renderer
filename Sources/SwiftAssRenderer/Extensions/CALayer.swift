#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Combine

extension CALayer {
    /// CALayer's `frame` is not key value observable, but rather a computed property
    /// (function of `bounds`, `position`, `anchorPoint` and `transform`). In order to observe the `frame` changes,
    /// we need to observe these properties instead.
    func onFrameChanged(
        _ action: @escaping () -> Void,
        storeCancellable: @escaping (AnyCancellable) -> Void
    ) {
        let boundsPub = publisher(for: \.bounds, options: [.initial, .new])
            .map { _ in }
            .eraseToAnyPublisher()
        let positionPub = publisher(for: \.position, options: [.initial, .new])
            .map { _ in }
            .eraseToAnyPublisher()
        let anchorPointPub = publisher(for: \.anchorPoint, options: [.initial, .new])
            .map { _ in }
            .eraseToAnyPublisher()
        let transformPub = publisher(for: \.transform, options: [.initial, .new])
            .map { _ in }
            .eraseToAnyPublisher()
        let cancellable = Publishers
            .MergeMany(boundsPub, positionPub, anchorPointPub, transformPub)
            .map { _ in }
            .sink(receiveValue: action)
        storeCancellable(cancellable)
    }
}
