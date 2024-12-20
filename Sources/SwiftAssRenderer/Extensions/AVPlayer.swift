import AVFoundation
import Combine

extension AVPlayer {
    func periodicTimeObserver(interval: CMTime, queue: DispatchQueue = .main) -> AnyPublisher<CMTime, Never> {
        Deferred { [weak self] in
            guard let self else {
                return Empty(outputType: CMTime.self, failureType: Never.self)
                    .eraseToAnyPublisher()
            }
            let subject = PassthroughSubject<CMTime, Never>()
            let observer = addPeriodicTimeObserver(forInterval: interval, queue: queue) { subject.send($0) }
            return subject.handleEvents(
                receiveCompletion: { [weak self] _ in self?.removeTimeObserver(observer) },
                receiveCancel: { [weak self] in self?.removeTimeObserver(observer) }
            ).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
