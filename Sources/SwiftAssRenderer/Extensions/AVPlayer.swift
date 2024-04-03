import AVFoundation
import Combine
import CombineExt

extension AVPlayer {
    func periodicTimeObserver(interval: CMTime, queue: DispatchQueue = .main) -> AnyPublisher<CMTime, Never> {
        AnyPublisher<CMTime, Never>.create { [weak self] subscriber in
            guard let self else {
                subscriber.send(completion: .finished)
                return AnyCancellable {}
            }
            let observer = addPeriodicTimeObserver(forInterval: interval, queue: queue) { time in
                subscriber.send(time)
            }

            return AnyCancellable { [weak self] in
                self?.removeTimeObserver(observer)
            }
        }
    }
}
